"""Export the ten-state (2,1) kick-level chain using matplotlib."""
from pathlib import Path
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch,Circle
R=Path(__file__).resolve().parent/'results'
pos={'A00':(0,2),'B00':(0,0),'B10':(2,2),'A10':(4,2),'B20':(6,2),'SD':(8,2),'SD1':(8,0),'SD0':(10,2),'Aw':(6,-2),'Bw':(2,-2)}
labels={'A00':'A:(0,0)','B00':'B:(0,0)','B10':'B:(1,0)','A10':'A:(1,0)','B20':'B:(2,0)','SD':'SD: A','SD1':'SD: B\nA scored','SD0':'SD: B\nA missed','Aw':'A wins','Bw':'B wins'}
edges=[('A00','B10','p',0),('A00','B00','1−p',-.1),('B00','A00','1−q',-.35),('B00','Bw','q',0),('B10','A10','1−q',0),('B10','Bw','q',0),('A10','B20','p',0),('A10','B10','1−p',.4),('B20','SD','q',0),('B20','Aw','1−q',0),('SD','SD1','p',.05),('SD','SD0','1−p',0),('SD1','SD','q',-.4),('SD1','Aw','1−q',.1),('SD0','SD','1−q',.5),('SD0','Bw','q',-.25)]
fig,ax=plt.subplots(figsize=(14,8));ax.set_xlim(-1,11);ax.set_ylim(-3,3.7);ax.set_aspect('equal');ax.axis('off')
for a,b,label,rad in edges:
 x,y=pos[a];xx,yy=pos[b];arrow=FancyArrowPatch((x,y),(xx,yy),connectionstyle=f'arc3,rad={rad}',arrowstyle='-|>',mutation_scale=14,shrinkA=28,shrinkB=28,color='#607779',linewidth=1.4);ax.add_patch(arrow)
 mx,my=(x+xx)/2,(y+yy)/2;dx,dy=xx-x,yy-y;mx+=rad*dy*.5;my-=rad*dx*.5
 ax.text(mx,my,label,ha='center',va='center',fontsize=10,bbox=dict(facecolor='white',edgecolor='none',pad=2))
for node,(x,y) in pos.items():
 ax.add_patch(Circle((x,y),.47,facecolor='#eef3ed' if node not in ('Aw','Bw') else '#f6e6d8',edgecolor='#166477',linewidth=1.6))
 if node in ('Aw','Bw'):ax.add_patch(Circle((x,y),.4,facecolor='none',edgecolor='#166477'))
 ax.text(x,y,labels[node],ha='center',va='center',fontsize=10)
ax.set_title('Figure 1 reconstruction: (2,1) ten-state absorbing chain',fontsize=17,pad=18)
fig.savefig(R/'figure1.svg',bbox_inches='tight');fig.savefig(R/'figure1.png',dpi=160,bbox_inches='tight');plt.close(fig)
