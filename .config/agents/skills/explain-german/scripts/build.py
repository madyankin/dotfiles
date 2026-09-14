#!/usr/bin/env python3
"""Build offline explainers from DATA JSON; stdlib only. No vault or network access."""
import argparse, collections, copy, json, re, zipfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
FIGURES = {'satzklammer':'saetze','kasus':'satz','wortstellung':'varianten','konjugator':'formen','trennbar':'varianten','glossen':'text','wortfeld':'cluster','feldermodell':'saetze','zeitstrahl':'punkte','raum':'praepositionen','valenz':'argumente','wortnetz':'knoten','wortbau':'teile','fehlerprofil':'kategorien'}
def require(ok, message):
    if not ok: raise ValueError(message)
def words(text):
    """Explanatory words only: markup and German markup spans still count as content."""
    return len(re.findall(r'\S+', re.sub(r'<[^>]+>', ' ', text or '')))
# Per-field ceilings on Russian explanation. Exceeding them means the point was not compressed.
CAPS = {'zweck':35,'intuition':45,'stuetzen':18,'warum':45,'details':60,'falle':30,
        'hinweis':14,'beobachtung':20,'merksatz':12,'leit':20}
BLOCK_BUDGET = 450  # explanatory words per learning block
def cap(field, text, where):
    n = words(text)
    require(n <= CAPS[field], f'{where}: {n} words, limit {CAPS[field]} — compress to the core')
    return n
def validate(d):
    require(isinstance(d,dict), 'DATA must be an object')
    m=d.get('meta',{}); slug=m.get('slug','')
    require(isinstance(slug,str) and re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*',slug), 'meta.slug must be safe kebab-case')
    for field in ['thema','niveau','modus','quelle','datum']: require(isinstance(m.get(field),str) and m[field].strip(),f'meta.{field} required')
    require(m['modus'] in ['text','grammatik','vokabeln','fehler'],'unknown mode')
    for field in ['zweck','intuition','stuetzen','analyse','figuren','fallen','quiz','karten']:
        require(isinstance(d.get(field),list) and len(d[field])>0,field+' must be nonempty list')
    anchor=d.get('leitbeispiel',{})
    require(isinstance(anchor,dict) and all(isinstance(anchor.get(k),str) and anchor[k].strip() for k in ['de','ru','ziel','grenze']),'leitbeispiel requires de, ru, ziel and grenze')
    require(len(d['quiz'])==5,'exactly five quiz questions required')
    require(collections.Counter(q.get('typ') for q in d['quiz'])=={'wahl':2,'eingabe':2,'ordnen':1},'quiz needs 2 wahl, 2 eingabe, 1 ordnen')
    for q in d['quiz']:
        require(bool(q.get('frage')),'question text required')
        require(q.get('typ') in ['wahl','eingabe','ordnen'],'unknown quiz type')
        require(isinstance(q.get('fokus'),str) and q['fokus'].strip(),'quiz focus required')
        if q['typ']=='wahl':
            opts=q.get('optionen',[])
            require(len(opts)>=2 and sum(o.get('ok') is True for o in opts)==1,'wahl needs exactly one correct choice')
            require(all(isinstance(o.get('ok'),bool) and o.get('t') and o.get('warum') for o in opts),'choice text, boolean and explanation required')
        elif q['typ']=='eingabe':
            require(isinstance(q.get('antworten'),list) and q['antworten'] and all(isinstance(a,str) and a.strip() for a in q['antworten']),'input answers required')
        else:
            parts=q.get('teile',[]); primary=q.get('loesung',[])
            require(parts and all(isinstance(x,str) and x for x in parts),'order tokens required')
            accepted=q.get('loesungen',[primary])
            require(isinstance(accepted,list) and accepted and primary in accepted,'include primary loesung in loesungen')
            require(all(isinstance(s,list) and collections.Counter(s)==collections.Counter(parts) for s in accepted),'every ordering must use the same token multiset')
        if q['typ']!='wahl': require(bool(q.get('warum')),'answer explanation required')
    merk=d.get('merksatz',[])
    require(isinstance(merk,list) and 1<=len(merk)<=3,'merksatz: 1–3 mnemonics required')
    require(all(isinstance(x,str) and x.strip() for x in merk),'each mnemonic is a nonempty string')
    floor=2 if m['modus'] in ['text','grammatik'] else 1
    require(floor<=len(d['figuren'])<=4,f'use {floor}–4 figures in {m["modus"]} mode')
    figure_ids=[f.get('id') for f in d['figuren']]
    require(all(isinstance(x,str) and re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*',x) for x in figure_ids),'every figure needs a safe id')
    require(len(set(figure_ids))==len(figure_ids),'figure ids must be unique')
    for f in d['figuren']:
        require(f.get('art') in FIGURES,'unknown figure')
        require(isinstance(f.get(FIGURES[f['art']]),list) and f[FIGURES[f['art']]],'figure data required')
        require(f.get('titel') and f.get('hinweis') and f.get('aria'),'figure title, instructions and aria description required')
    if m['modus']=='text': require(any(f['art']=='glossen' for f in d['figuren']),'text needs glossen')
    require(5<=len(d['karten'])<=12 and all(k.get('v') and k.get('r') for k in d['karten']),'5–12 complete cards required')
    for a in d['analyse']:
        require(all(a.get(k) for k in ['de','frei','warum']),'analysis requires German, natural translation and explanation')
        if 'herkunft' in a: require(a['herkunft'] in ['zitat','loesung','beispiel'],'unknown provenance')
        if 'details' in a:
            require(isinstance(a['details'],list) and all(x.get('titel') and x.get('text') for x in a['details']),'analysis details need title and text')
    require(any(a.get('anker') is True for a in d['analyse']),'reuse the anchor example in analysis')
    mounted=[a.get('figure_id') for a in d['analyse'] if a.get('figure_id')]
    require(collections.Counter(mounted)==collections.Counter(figure_ids),'mount every figure exactly once in analysis')
    linked=[q.get('figure_id') for q in d['quiz'] if q.get('figure_id')]
    require(linked and all(x in figure_ids for x in linked),'at least one quiz question must reference a figure')
    if 'requested_pages' in m:
        require(set(map(str,m['requested_pages']))==set(map(str,m.get('pages',[]))),'requested and covered printed pages differ')
    for key in ['reference','solutions']:
        for item in d.get(key,[]):
            require(item.get('titel') and (item.get('text') or item.get('kopf')),'appendix needs title and content')
            if 'kopf' in item: require(item['kopf'] and all(len(r)==len(item['kopf']) for r in item.get('zeilen',[])),'ragged appendix table')
    spent=sum(cap('zweck',t,f'zweck[{i}]') for i,t in enumerate(d['zweck']))
    spent+=sum(cap('intuition',b.get('text',''),f'intuition[{i}]') for i,b in enumerate(d['intuition']) if b.get('art')=='p')
    spent+=sum(cap('stuetzen',t,f'stuetzen[{i}]') for i,t in enumerate(d['stuetzen']))
    spent+=sum(cap('merksatz',t,f'merksatz[{i}]') for i,t in enumerate(merk))
    spent+=sum(cap('leit',anchor[k],f'leitbeispiel.{k}') for k in ['ziel','grenze'])
    for i,a in enumerate(d['analyse']):
        spent+=cap('warum',a['warum'],f'analyse[{i}].warum')
        spent+=sum(cap('details',x['text'],f'analyse[{i}].details[{j}]') for j,x in enumerate(a.get('details',[])))
    spent+=sum(cap('falle',f.get('warum') or f.get('text',''),f'fallen[{i}]') for i,f in enumerate(d['fallen']))
    for f in d['figuren']:
        spent+=cap('hinweis',f['hinweis'],f'figur {f["id"]}.hinweis')+cap('beobachtung',f.get('beobachtung',''),f'figur {f["id"]}.beobachtung')
    blocks=max(1,sum(1 for a in d['analyse'] if a.get('titel')))
    budget=BLOCK_BUDGET*blocks
    require(spent<=budget,f'{spent} explanatory words for {blocks} block(s), budget {budget} — drop in order: details, дословно, stuetzen, intuition paragraphs')
    d['meta']['woerter']=spent
    return d

def render(d):
    validate(d)
    d=copy.deepcopy(d)
    # Different correct positions by construction, without changing authored content.
    for i,q in enumerate(q for q in d['quiz'] if q['typ']=='wahl'):
        opts=q['optionen']; correct=next(o for o in opts if o['ok'])
        opts.remove(correct); opts.insert(i % (len(opts)+1),correct)
    template=(ROOT/'assets/template.html').read_text()
    begin=template.index('const DATA = ')
    end=template.index('\n/* ============================================================================\n   RENDER',begin)
    payload=json.dumps(d,ensure_ascii=False,indent=2).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
    return template[:begin]+'const DATA = '+payload+';\n'+template[end:]

def build(paths,out,overwrite=False):
    docs=[validate(json.loads(Path(p).read_text())) for p in paths]
    slugs=[d['meta']['slug'] for d in docs]
    require(len(set(slugs))==len(slugs),'duplicate slug in batch')
    targets=[out/(s+'.html') for s in slugs]
    if len(docs)>1: targets.append(out/'explainers.zip')
    require(overwrite or not any(p.exists() for p in targets),'output exists; choose new folder or use --overwrite deliberately')
    rendered=[render(d) for d in docs]  # validate entire batch before writing
    out.mkdir(parents=True,exist_ok=True)
    for file,text in zip(targets,rendered): file.write_text(text)
    if len(docs)>1:
        with zipfile.ZipFile(targets[-1],'w',zipfile.ZIP_DEFLATED) as z:
            for file in targets[:-1]: z.write(file,file.name)
    return targets
if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('data',nargs='+',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--overwrite',action='store_true')
    args=ap.parse_args()
    try:
        for file in build(args.data,args.out,args.overwrite): print(file.resolve())
    except (ValueError,KeyError,TypeError,OSError) as e: ap.exit(1,f'Build failed: {e}\n')
