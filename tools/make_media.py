"""Original procedural UI masks; no copied XPIsland media or font files."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'.work/pydeps'))
from PIL import Image,ImageDraw
target=ROOT/'AsTheCrowFlies/Media';target.mkdir(exist_ok=True)
def save(name,draw):
    im=Image.new('RGBA',(256,256),(255,255,255,0));d=ImageDraw.Draw(im);draw(d)
    im.resize((64,64),Image.Resampling.LANCZOS).save(target/(name+'.tga'))
save('surface',lambda d:d.rounded_rectangle((0,0,255,255),radius=18,fill='white'))
save('arrow',lambda d:d.polygon([(128,16),(232,228),(128,179),(24,228)],fill='white'))
def crow(d):
    # Side-on crow: rounded crown, stout straight beak, folded wing and fan tail.
    # Keep the existing texture filename so a reload can replace it in place.
    points=[(31,205)]
    def curve(control1,control2,end):
        start=points[-1]
        for step in range(1,25):
            t=step/24;u=1-t
            points.append((u*u*u*start[0]+3*u*u*t*control1[0]+3*u*t*t*control2[0]+t*t*t*end[0],
                           u*u*u*start[1]+3*u*u*t*control1[1]+3*u*t*t*control2[1]+t*t*t*end[1]))
    points.append((65,137));curve((79,109),(114,104),(132,84))
    curve((140,74),(140,53),(159,43));curve((179,31),(204,40),(208,60))
    points.extend([(240,75),(239,83),(207,84)])
    curve((198,92),(204,105),(191,130));curve((179,158),(151,178),(116,174))
    points.extend([(61,223),(50,219),(51,209),(39,215),(31,205)])
    d.polygon(points,fill='white')
    # Two short legs and spread toes retain the perched profile at small sizes.
    d.line([(136,167),(143,205),(127,212)],fill='white',width=9)
    d.line([(143,205),(163,213)],fill='white',width=7)
    d.line([(160,156),(176,191),(194,196)],fill='white',width=8)
    d.line([(176,191),(166,201)],fill='white',width=7)
    d.ellipse((187,58,194,65),fill=(255,255,255,0))
save('eagle',crow)
print('Generated three original RGBA masks')
