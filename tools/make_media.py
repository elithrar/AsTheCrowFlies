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
save('eagle',lambda d:d.polygon([(128,110),(147,83),(170,90),(149,108),(157,127),(238,54),(221,108),(184,148),(154,160),(145,178),(165,207),(130,197),(102,213),(105,182),(94,162),(65,153),(31,120),(13,55),(101,123),(114,117)],fill='white'))
print('Generated three original RGBA masks')
