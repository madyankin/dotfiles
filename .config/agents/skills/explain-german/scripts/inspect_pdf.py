#!/usr/bin/env python3
"""Extract per-page text/labels and optionally render chosen 1-based PDF pages.
Requires pypdf; rendering additionally requires pypdfium2 and Pillow.
Does not infer printed page numbers or perform OCR.
"""
import argparse,json
from pathlib import Path
from pypdf import PdfReader
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('pdf',type=Path);ap.add_argument('--out',required=True,type=Path)
ap.add_argument('--render',nargs='*',type=int,default=[]);ap.add_argument('--rotate',type=int,choices=[0,90,180,270],default=0)
a=ap.parse_args(); r=PdfReader(a.pdf)
if any(n<1 or n>len(r.pages) for n in a.render):ap.error('render page out of range')
a.out.mkdir(parents=True,exist_ok=True); report=[]
for i,page in enumerate(r.pages,1):
    t=page.extract_text() or '';(a.out/f'pdf-{i:03}.txt').write_text(t)
    report.append(dict(pdf_page=i,pdf_label=r.page_labels[i-1],words=len(t.split()),needs_visual_review=not t.strip(),printed_pages=[]))
(a.out/'page-map.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
if a.render:
    import pypdfium2 as pdfium
    doc=pdfium.PdfDocument(str(a.pdf))
    for n in a.render:
        image=doc[n-1].render(scale=1.5).to_pil().rotate(a.rotate,expand=True)
        image.save(a.out/f'pdf-{n:03}.png')
print(a.out/'page-map.json')
