import copy,json,tempfile,unittest,zipfile
from pathlib import Path
from build import build,render,validate

def fixture():
 return dict(meta=dict(slug='test-one',thema='Test',niveau='B1',modus='grammatik',quelle='test',datum='2026-09-13',requested_pages=['19'],pages=['19']),zweck=['test'],intuition=[dict(art='p',text='test')],leitbeispiel=dict(de='Test',ru='Тест',ziel='Следи за формой',grenze='Не переносить на исключения'),stuetzen=['test'],merksatz=['Двигается — Akkusativ'],analyse=[dict(de='Test',frei='test',warum='test',anker=True,figure_id='test-figure'),dict(de='Test2',frei='test',warum='test',figure_id='test-figure-2')],figuren=[dict(id='test-figure',art='konjugator',titel='Test',hinweis='Test',aria='Сравнение форм',formen=[dict(label='Test',satz='Test')]),dict(id='test-figure-2',art='valenz',titel='Test',hinweis='Test',aria='Роли глагола',verb='helfen',satz='Ich helfe dir.',argumente=[dict(rolle='wem?',kasus='dat',beispiel='dir')])],fallen=[dict(text='test')],quiz=[dict(typ='wahl',fokus=f'choice-{i}',figure_id='test-figure' if i==0 else None,frage='?',optionen=[dict(t='a',ok=True,warum='a'),dict(t='b',ok=False,warum='b')]) for i in range(2)]+[dict(typ='eingabe',fokus=f'input-{i}',frage='?',antworten=['a'],warum='a') for i in range(2)]+[dict(typ='ordnen',fokus='order',frage='?',teile=['A','B'],loesung=['A','B'],loesungen=[['A','B'],['B','A']],warum='a')],karten=[dict(v='a',r='b') for _ in range(5)])
class Tests(unittest.TestCase):
 def test_valid(self):validate(fixture())
 def test_budget(self):
  d=fixture();d['analyse'][0]['warum']='слово '*46
  with self.assertRaises(ValueError):validate(d)      # per-field cap
  d=fixture();d['stuetzen']=['слово '*10 for _ in range(50)]
  with self.assertRaises(ValueError):validate(d)      # block budget
  d=fixture();d['analyse'][0]['titel']='Блок 1';d['analyse'][1]['titel']='Блок 2'
  d['stuetzen']=['слово '*10 for _ in range(50)]
  validate(d)                                         # two blocks buy two budgets
 def test_invalid(self):
  for mutate in [lambda d:d['quiz'].pop(),lambda d:d.pop('merksatz'),lambda d:d.update(merksatz=[]),
                 lambda d:d.update(merksatz=['a','b','c','d']),lambda d:(d['figuren'].pop(),d['analyse'].pop()),lambda d:d['meta'].update(slug='../x'),lambda d:d['meta'].update(pages=['20']),lambda d:d['quiz'][-1].update(loesungen=[['A','A']]),lambda d:d['quiz'][0]['optionen'][1].update(ok=True),lambda d:d['analyse'][0].pop('figure_id'),lambda d:d['quiz'][0].pop('figure_id')]:
   d=fixture();mutate(d)
   with self.assertRaises(ValueError):validate(d)
 def test_script_escape(self):
  d=fixture();d['zweck']=['</script><script>bad()</script>'];s=render(d)
  self.assertEqual(s.count('</script>'),1)
 def test_batch_zip_and_overwrite(self):
  with tempfile.TemporaryDirectory() as td:
   root=Path(td);paths=[]
   for i in range(2):
    d=fixture();d['meta']['slug']=f'test-{i}';p=root/f'{i}.json';p.write_text(json.dumps(d));paths.append(p)
   files=build(paths,root/'out');self.assertEqual(len(files),3)
   with zipfile.ZipFile(files[-1]) as z:self.assertEqual(len(z.namelist()),2);self.assertIsNone(z.testzip())
   with self.assertRaises(ValueError):build(paths,root/'out')
if __name__=='__main__':unittest.main()
