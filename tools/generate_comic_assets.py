"""Author the game's comic art as editable SVG, then render with render_comic_assets.gd.
No external packages. All repeating scenery is periodic in geometry and shading.
"""
from pathlib import Path
import json, math, re
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/art/comic'
INK = '#382b3d'
manifest = []

def path(d, fill, stroke=INK, sw=3, extra=''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'
def ellipse(x,y,rx,ry,fill,stroke='none',sw=3):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def rect(x,y,w,h,fill,r=0,stroke='none',sw=3):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def gradient(name,a,b,radial=False):
    if radial:
        return f'<radialGradient id="{name}" cx="30%" cy="23%" r="85%"><stop stop-color="{a}"/><stop offset="1" stop-color="{b}"/></radialGradient>'
    return f'<linearGradient id="{name}" x2="0" y2="1"><stop stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'
def emit(name,w,h,body,defs=''):
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{defs}</defs>{body}</svg>'
    # NanoSVG accepts SVG 1.1 opacity attributes, not CSS eight-digit hex.
    svg=re.sub(r'fill="(#[0-9a-fA-F]{6})([0-9a-fA-F]{2})"', lambda m: f'fill="{m[1]}" fill-opacity="{int(m[2],16)/255:.4f}"', svg)
    dest=OUT/'source'/Path(name).with_suffix('.svg')
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(svg)
    manifest.append(name)
def cloud(x=0,y=0,s=1):
    return f'<g transform="translate({x} {y}) scale({s})">'+path('M 12 79 C -3 56 15 38 39 42 C 40 4 99 -2 116 34 C 147 14 180 35 179 57 C 218 50 237 80 209 94 C 166 107 43 103 12 79 Z','#fffaf0','#809ca5',2)+path('M 23 81 Q 99 95 202 84','none','#d9e8e4',8)+'</g>'
def leaf(x,y,s=1,color='#58946c'):
    return f'<g transform="translate({x} {y}) scale({s})">'+path('M 0 0 Q -26 -38 -4 -61 Q 28 -32 0 0 Z',color,INK,2)+path('M 0 -5 L -3 -43','none','#c6dc9f',2)+'</g>'
def flower(x,y,s=1,color='#fff1d2'):
    return f'<g transform="translate({x} {y}) scale({s})">'+path('M 0 9 Q -3 -3 2 -12','none','#4d7858',3)+''.join(ellipse(math.cos(a)*7,math.sin(a)*7-13,5,5,color) for a in [0,1.25,2.5,3.75,5])+ellipse(0,-13,3.5,3.5,'#e9aa46')+'</g>'

colors={'pink':('#f492b6','#dc568b'),'green':('#6fa887','#427d61'),'gold':('#f8d783','#eab052'),'cream':('#fffaf0','#f4e1bc'),'lilac':('#b89acb','#9270af'),'sky':('#b8edee','#78cbdc')}
for name,(light,base) in colors.items():
    for state in ['idle','pressed']:
        y=7 if state=='pressed' else 2
        body=rect(2,8,92,84,INK,24)+rect(2,y,92,84,'url(#face)',24,INK,3)
        if state=='idle': body+=path('M 17 27 Q 17 13 31 13 L 65 13','none','#ffffff',3,extra='opacity=".45"')
        emit(f'ui_redesign/buttons/{name}_{state}.png',96,96,body,gradient('face',light,base))
for name in ['cream','cream_pink','dark','sky','green','gold','lilac']:
    light,base=colors.get(name,('#51445b','#382b3d') if name=='dark' else colors['cream'])
    border='#b45d82' if name=='cream_pink' else INK
    for state in ['raised','flat']:
        shadow=rect(2,6,92,87,'#756479',16) if state=='raised' else ''
        emit(f'ui_redesign/panels/{name}_{state}.png',96,96,shadow+rect(2,2,92,87,'url(#face)',16,border,2.5),gradient('face',light,base))
for prefix,s in [('large',1),('small',.62)]:
    for name,stretch in [('wide',1),('tall',.84),('wisp',1.22)]:
        emit(f'ui_redesign/clouds/{prefix}_{name}.png',round(240*s*stretch),round(112*s),f'<g transform="scale({s*stretch} {s})">'+cloud()+'</g>')
emit('sky.png',720,1565,rect(0,0,720,1565,'url(#sky)')+ellipse(598,236,84,84,'#fff5cb')+ellipse(575,213,13,13,'#fffaf0'),gradient('sky','#84ccdf','#e4efe2'))
# Crisp, expressive care and navigation icons.
gear=''
for i in range(8): gear+=f'<g transform="rotate({i*45} 32 32)">'+rect(26,3,12,19,INK,4)+'</g>'
gear+=ellipse(32,32,23,23,INK)+ellipse(32,32,17,17,'#fff1d2')+ellipse(32,32,8,8,INK)
emit('ui_redesign/icons/settings_gear.png',64,64,gear)
emit('ui_redesign/icons/sunberry.png',96,96,ellipse(48,84,29,7,'#382b3d22')+path('M 47 29 C 12 12 7 53 27 77 Q 48 97 71 74 C 94 47 75 12 47 29 Z','url(#berry)',INK,3)+leaf(49,32,.4)+path('M 30 39 Q 20 46 25 58','none','#fff1d2',5)+ellipse(64,61,2,3,'#a34362'),gradient('berry','#ffb078','#e75d91',True))
comb=path('M 20 18 Q 11 14 10 25 L 12 37 L 84 37 L 85 26 Q 85 18 76 18 Z','url(#comb)',INK,3)
for x in range(17,83,10): comb+=rect(x,33,6,42,'#efd1a2',3,INK,2)
emit('ui_redesign/icons/grooming_comb.png',96,96,'<g transform="rotate(-18 48 48)">'+comb+'</g>',gradient('comb','#ffc6ce','#e75d91'))
# Elemental eggs have a continuous shell, a soft key light and restrained emblems.
elements={'sun':('#fff1d2','#eaa754'),'fire':('#f8b379','#d95852'),'water':('#aff0ec','#469bc1'),'earth':('#dcda9c','#709c68'),'ice':('#f5fcff','#8ebfdd'),'storm':('#c0ace1','#78609c'),'lava':('#f6aa6e','#85506b'),'mud':('#c6d99e','#7d9562')}
egg_names={'sun':'sun_egg.png','fire':'fire/fire_egg.png','water':'water/water_egg.png','earth':'earth/earth_egg.png','ice':'ice/ice_egg.png','storm':'fusion/fusion_egg.png','lava':'fusion/lava/lavara_egg.png','mud':'fusion/mud/mudara_egg.png'}
for name,(light,shade) in elements.items():
    body=ellipse(128,271,79,15,'#382b3d22')+path('M 128 15 C 91 15 37 107 35 180 C 30 289 226 289 221 180 C 219 107 165 15 128 15 Z','url(#egg)',INK,5)+path('M 80 71 Q 58 105 56 135','none','#fffaf0',9,extra='opacity=".65"')
    emblems={
        'sun': 'M 128 113 L 137 140 L 165 142 L 143 160 L 151 187 L 128 171 L 105 187 L 113 160 L 91 142 L 119 140 Z',
        'fire': 'M 131 108 Q 144 139 134 155 Q 153 146 151 132 Q 174 176 143 190 Q 104 207 99 172 Q 99 149 119 140 Q 110 167 123 166 Q 134 151 131 108 Z',
        'water': 'M 128 112 C 118 142 101 152 103 170 C 105 201 153 201 155 170 C 157 152 137 133 128 112 Z',
        'earth': 'M 110 186 Q 87 132 157 119 Q 177 178 110 186 Z M 111 184 L 145 138',
        'ice': 'M 128 111 L 128 193 M 95 131 L 161 173 M 95 173 L 161 131 M 118 122 L 128 132 L 138 122 M 118 182 L 128 172 L 138 182',
        'storm': 'M 132 108 L 101 159 L 124 155 L 117 199 L 157 142 L 132 147 Z',
        'lava': 'M 93 188 L 114 125 L 139 125 L 164 188 Z M 116 142 L 128 165 L 139 142',
        'mud': 'M 95 175 Q 111 158 125 174 Q 141 188 161 171 L 160 187 Q 141 204 123 189 Q 104 179 95 191 Z M 124 161 Q 104 131 142 120 Q 151 151 124 161 Z'
    }
    body+=path(emblems[name], 'none' if name=='ice' else light, light if name=='ice' else INK, 5 if name=='ice' else 3)

    body+=ellipse(78,206,10,7,light)+ellipse(175,113,7,11,light)+ellipse(177,220,12,8,light)
    emit(egg_names[name],256,292,body,gradient('egg',light,shade,True))
# A family of floating islands. Art stays behind the existing habitat hit areas.
island_names={'sun':'dragon_island_hd.png','fire':'fire/fire_island_hd.png','water':'water/water_island_hd.png','earth':'earth/earth_island_hd.png','ice':'ice/ice_island_hd.png','storm':'fusion/voltara_island_hd.png','lava':'fusion/lava/lavara_island_hd.png','mud':'fusion/mud/mudara_island_hd.png'}
for name in elements:
    light,shade=elements[name]
    grass={'fire':'#d5b376','earth':'#dec69a','ice':'#e5f2ed','storm':'#a9b2b9','lava':'#be8f83','mud':'#a5bc80'}.get(name,'#afd393')
    sky={'fire':'#e8bfab','ice':'#a9cddd','storm':'#b6adce','lava':'#d0a3b2'}.get(name,'#89cddd')
    b=rect(0,0,720,1565,'url(#sky)')+ellipse(555,255,66,66,'#fff4cd')
    b+=cloud(36,155,.85)+cloud(465,360,1.12)+cloud(-80,478,.65)
    # Airborne distant islands establish distance without cluttering the hero.
    for x,y,s in [(47,540,.38),(549,532,.46)]:
        b+=f'<g opacity=".44" transform="translate({x} {y}) scale({s})">'+path('M 0 40 Q 70 12 144 40 Q 105 90 76 120 Q 40 103 0 40 Z','#8499a0','none')+ellipse(72,40,73,20,'#c4d8b6')+'</g>'
    b+=ellipse(359,1062,240,35,'#839b9822')
    b+=path('M 47 755 C 67 833 124 854 159 903 C 195 949 239 921 277 999 Q 308 1038 343 1008 Q 376 971 422 1002 Q 468 1015 488 948 C 528 911 547 931 578 872 Q 650 837 676 755 Z','url(#rock)',INK,5)
    b+=path('M 98 787 Q 162 802 197 893 L 207 926 M 292 828 Q 279 918 305 972 M 508 812 Q 489 890 474 925 M 568 805 L 543 852','none','#806b80',5)
    b+=path('M 193 849 Q 220 857 236 880 L 254 933 Q 222 903 209 897 Z','#dac5a3','none')
    b+=path('M 46 744 C 42 657 173 594 324 614 C 459 578 672 642 677 738 C 706 819 532 856 363 846 C 198 863 22 827 46 744 Z','url(#grass)',INK,5)
    b+=path('M 64 752 C 146 820 280 811 359 822 Q 557 840 659 771','none','#edf0c1',6)
    b+=path('M 126 733 C 100 680 194 657 253 686 C 301 712 251 751 219 757 Q 145 783 126 733 Z','#f7e9c4',INK,3)
    b+=path('M 137 728 C 118 691 194 672 245 696 C 276 714 235 744 206 745 Q 146 762 137 728 Z','url(#pond)','#5b98a1',2)
    b+=path('M 150 719 Q 178 704 212 711 M 167 733 Q 190 738 220 727','none','#e5f8ed',4)
    # Rounded rocks, leaves, flowers and a little winding path.
    b+=path('M 426 640 Q 378 685 438 727 Q 500 763 475 802','none','#f0d8ac',30)
    for x,y,s in [(99,728,1.1),(569,750,1.3),(548,677,.8),(282,658,.6)]:
        b+=ellipse(x,y+9,35*s,12*s,'#5a625533')
        b+=path(f'M {x-28*s} {y} Q {x-29*s} {y-35*s} {x-6*s} {y-42*s} Q {x+20*s} {y-45*s} {x+31*s} {y-7*s} Q {x+17*s} {y+12*s} {x-28*s} {y} Z','#c9c7b4',INK,3)
        b+=path(f'M {x-18*s} {y-19*s} Q {x-9*s} {y-33*s} {x+8*s} {y-30*s}','none','#fff0cf',4)
    for x,y,s in [(94,681,.9),(605,712,1),(528,650,.7)]:
        if name=='ice':
            b+=path(f'M {x-18} {y} L {x-11} {y-59} L {x+2} {y-77} L {x+21} {y-40} L {x+15} {y} Z','#b8e5ef',INK,3)
            b+=path(f'M {x+2} {y-67} L {x+3} {y-8}','none','#fffaf0',4)
        else:
            b+=leaf(x,y,s,shade)+leaf(x+10,y,.7*s,'#8ab586')+f'<g transform="rotate(-37 {x} {y})">'+leaf(x,y,.8*s,'#589576')+'</g>'
    for i in range(18):
        x=100+(i*103)%510; y=771+(i*17)%40
        b+=flower(x,y,.55+(i%3)*.1,light if i%2 else '#fffaf0')
    if name in ('water','ice'):
        b+=path('M 206 789 Q 188 848 218 894 Q 251 957 216 1086 L 247 1086 Q 292 970 256 884 Q 239 835 263 810 Z','#9fdadd','#5b98a1',3)
        b+=path('M 230 824 Q 216 860 247 931 Q 262 1000 234 1066','none','#e5fbf3',7)
    b+=cloud(-95,1005,1.35)+cloud(555,958,1.15)
    if name in ('fire','lava'):
        b=b.replace('#e5f8ed','#ffe6a8').replace('#5b98a1','#ad6f61')
        b+=path('M 314 853 L 304 884 L 322 910 L 311 955 M 485 845 L 475 866 L 486 890','none','#f8b77c',6)
        b+=path('M 314 853 L 304 884 L 322 910 L 311 955','none','#fff0b1',2)
    if name=='storm':
        b+=path('M 564 589 L 544 622 L 559 619 L 551 646 L 582 609 L 565 613 Z','#fff1d2',INK,2)
    if name in ('water','mud'):
        b+=path('M 165 726 Q 164 706 187 708 Q 204 711 191 729 L 180 719 L 181 733 Z','#9ec287','#527f73',2)+flower(171,717,.6,'#efb0c5')
    pond=('#f3b973','#e98665') if name in ('fire','lava') else (('#9aad8c','#bacd9f') if name=='mud' else ('#70c4ce','#b0e1db'))
    rock=('#aa8d95','#63536e') if name=='lava' else ('#b8a2a5','#6e627e')
    emit(island_names[name],720,1565,b,gradient('sky',sky,'#e5eee0')+gradient('rock',*rock)+gradient('grass','#e2e9b7',grass)+gradient('pond',*pond))
# Horizontal flight portraits. The source faces left; gameplay flips right.
flight_names={'sun':'flight/flight_dragon.png','fire':'flight/dragons/ember_flight.png','water':'flight/dragons/marina_flight.png','earth':'flight/dragons/terra_flight.png','ice':'flight/dragons/frost_flight.png','storm':'flight/dragons/voltara_flight.png','lava':'flight/dragons/lavara_flight.png','mud':'flight/dragons/mudara_flight.png'}
for name,(light,shade) in elements.items():
    base='#e75d91' if name=='sun' else shade
    defs=gradient('body',light,base,True)+gradient('wing',light,base)
    b=path('M 196 100 Q 244 57 311 64 Q 284 78 280 108 Q 310 130 336 114 Q 320 153 290 145 Q 244 116 197 139 Z','url(#body)',INK,4)
    b+=path('M 158 99 C 162 64 180 23 235 7 Q 219 37 223 68 Q 191 49 197 96 L 169 128 Z','url(#wing)',INK,4)
    b+=path('M 160 134 Q 211 90 250 116 Q 258 142 216 150 Q 192 160 160 148 Z','url(#body)',INK,4)
    b+=path('M 136 128 Q 151 164 178 169 L 174 178 L 148 174 Q 131 157 122 145 Z',base,INK,3)
    b+=path('M 104 95 Q 170 57 203 105 Q 219 142 171 157 Q 129 166 91 138 Z','url(#body)',INK,4)
    b+=path('M 152 111 Q 171 45 135 12 Q 192 24 211 62 L 247 88 Q 219 82 215 107 Q 180 89 170 134 Z','url(#wing)',INK,4)
    b+=path('M 166 45 Q 187 70 193 96 M 192 62 L 226 88','none',INK,2)
    b+=path('M 102 83 Q 74 54 42 77 Q 22 89 27 105 Q 6 106 10 125 Q 21 147 66 142 Q 113 146 121 119 Z','url(#body)',INK,4)
    b+=path('M 80 75 Q 76 48 91 36 Q 100 57 97 83 Z','#fff1d2',INK,3)
    b+=ellipse(48,102,11,14,'#fffaf0',INK,2)+ellipse(45,103,5,9,INK)+ellipse(44,99,2,3,'#fffaf0')+ellipse(18,117,3,2,INK)
    b+=path('M 29 132 Q 51 138 71 128','none',INK,3)+path('M 112 139 Q 117 161 141 160 L 145 169 Q 113 180 99 148 Z',base,INK,3)
    emit(flight_names[name],348,190,b,defs)
# Opponents share the flight anatomy, with distinct silhouettes/colors from elements.
for target,source in [('red','fire'),('green','earth'),('blue','water')]:
    svg=(OUT/'source'/Path(flight_names[source]).with_suffix('.svg')).read_text()
    dest=f'flight/opponents/{target}_flight.png'; p=OUT/'source'/Path(dest).with_suffix('.svg'); p.parent.mkdir(parents=True,exist_ok=True); p.write_text(svg); manifest.append(dest)
# Each hill begins and ends with identical height and derivative: seamless horizontally.
for name,a,b,baseline,amplitude in [('mountains','#b7ced5','#86a9ba',260,140),('landscape','#acd1b0','#719c8b',270,95),('foreground','#cde2a1','#83b27c',65,22)]:
    w,h=1440,420 if name!='foreground' else 180
    points=[]
    for x in range(0,w+1,6):
        y=baseline-amplitude*(.52+.32*math.sin(x*2*math.pi/w)+.16*math.cos(x*4*math.pi/w))
        points.append(f'{x},{y:.3f}')
    d='M '+' L '.join(points)+f' L {w},{h} L 0,{h} Z'
    body=path(d,'url(#hill)','none')+path('M '+' L '.join(points),'none','#607e86' if name=='mountains' else '#547963',2)
    if name=='foreground':
        for i in range(24):
            x=22+i*59;y=95+(i*23)%60
            body+=path(f'M {x-6} {y} Q {x-4} {y-10} {x-12} {y-16} M {x-4} {y} Q {x+1} {y-16} {x+10} {y-19}','none','#619664',2)
    emit(f'ui_redesign/flight_environment/{name}.png',w,h,body,gradient('hill',a,b))
# Vertical field: its path and all background colors meet at y=0/840; landmarks stay clear of edges.
b=rect(0,0,720,840,'#b4cf92')
b+=path('M 360 -50 C 360 95 440 123 440 210 C 440 315 280 315 280 420 C 280 525 440 525 440 630 C 440 717 360 745 360 890','none','#d7daac',144)
b+=path('M 360 -50 C 360 95 440 123 440 210 C 440 315 280 315 280 420 C 280 525 440 525 440 630 C 440 717 360 745 360 890','none','#e6dfb8',112)
# Better exact wrap: use a periodic sinuous strip with matched x and tangents.
pts=[(360+72*math.sin(2*math.pi*y/840),y) for y in range(0,841,4)]
b=rect(0,0,720,840,'#b4cf92')+path('M '+' L '.join(f'{x-64:.3f},{y}' for x,y in pts)+' L '+' L '.join(f'{x+64:.3f},{y}' for x,y in reversed(pts))+' Z','#e5deb7','none')
for i in range(26):
    x=40+(i*137)%640; y=35+(i*79)%760
    if 265<x<490: continue
    b+=ellipse(x,y+12,22,8,'#98b881')+flower(x,y,.65,'#fff2d0' if i%2 else '#efaab0')
    b+=path(f'M {x+18} {y+20} Q {x+22} {y+8} {x+16} {y+3} M {x+22} {y+20} Q {x+28} {y+9} {x+33} {y+8}','none','#6a9c71',2)
for x,y in [(101,218),(582,433),(154,677)]:
    b+=ellipse(x,y+12,34,13,'#82997455')+path(f'M {x-27} {y} Q {x-23} {y-35} {x+6} {y-28} Q {x+36} {y-20} {x+27} {y+5} Q {x} {y+21} {x-27} {y} Z','#b5bdae','#687d75',3)+path(f'M {x-15} {y-10} Q {x-5} {y-25} {x+9} {y-17}','none','#e0e3c7',4)
emit('flame_minigame/ground.png',720,840,b)
# Top-down knight: helmet, visor, cape and rounded shield read clearly in motion.
b=ellipse(91,129,53,26,'#382b3d28')+path('M 62 69 Q 31 86 39 156 Q 82 183 126 155 Q 136 99 108 72 Z','url(#cape)',INK,4)
b+=rect(56,133,21,36,'#655970',9,INK,3)+rect(91,133,21,36,'#655970',9,INK,3)
b+=ellipse(84,91,37,37,'url(#metal)',INK,4)+ellipse(84,57,30,29,'url(#metal)',INK,4)
b+=path('M 59 59 Q 84 68 110 59 L 104 76 Q 86 88 64 75 Z','#4d4a63',INK,2)+path('M 70 69 L 77 70 M 89 70 L 97 69','none','#f2e7cd',3)
b+=path('M 83 32 Q 66 16 86 7 Q 115 13 101 35 Z','#e75d91',INK,3)
b+=path('M 118 81 L 151 77 L 153 115 Q 137 134 121 116 Z','#efc275',INK,4)+path('M 136 86 L 136 116 M 127 101 L 146 101','none','#fff1d2',4)
b+=path('M 39 113 L 24 53 L 29 37 L 38 51 L 47 111 Z','#e6eeeb',INK,3)+path('M 28 112 L 55 106','none','#c9a26e',6)
emit('flame_minigame/knight_top_down.png',180,190,b,gradient('metal','#f0f3e8','#8eabc2',True)+gradient('cape','#e889a4','#a95279'))
b=path('M 94 199 Q 104 227 86 273 Q 123 255 126 218 L 111 188 Z','url(#body)',INK,4)
for flip in ['', 'translate(220 0) scale(-1 1)']:
    b+=f'<g transform="{flip}">'+path('M 91 146 Q 71 73 14 81 Q 34 99 15 148 Q 47 128 59 179 Q 72 163 94 177 Z','url(#wing)',INK,4)+path('M 82 146 Q 59 113 31 97 M 61 131 L 59 167','none',INK,2)+path('M 91 178 Q 62 188 63 210 L 81 213 L 106 187 Z','#d76086',INK,3)+'</g>'
b+=ellipse(110,149,37,66,'url(#body)',INK,4)+path('M 98 89 Q 86 52 110 19 Q 134 52 123 89 Z','#fff1d2',INK,3)+ellipse(110,72,32,36,'url(#body)',INK,4)+rect(84,38,52,38,'url(#body)',18,INK,4)
b+=ellipse(88,55,5,10,'#fffaf0',INK,2)+ellipse(132,55,5,10,'#fffaf0',INK,2)+ellipse(87,51,2.5,5,INK)+ellipse(133,51,2.5,5,INK)
for y in [108,129,150,171]: b+=path(f'M 104 {y+8} L 110 {y-6} L 116 {y+8} Z','#fff1d2',INK,2)
emit('flame_minigame/dragon_top_down.png',220,286,b,gradient('body','#ffb0b9','#d95789',True)+gradient('wing','#ffe3bb','#db839f'))
b=path('M 48 6 C 43 39 13 40 13 68 C 9 110 90 118 83 71 Q 81 48 64 42 Q 67 70 54 64 Q 61 34 48 6 Z','url(#fire)',INK,3)+path('M 46 48 Q 47 76 31 79 Q 23 100 49 102 Q 72 100 66 79 Q 62 88 54 83 Z','#fff5c4','none')
emit('flame_minigame/flame.png',96,118,b,gradient('fire','#ffe3a0','#f08c63'))
flag=path('M 10 8 Q 27 0 44 8 Q 56 13 65 6 L 65 40 Q 50 48 37 40 Q 23 34 10 42 Z','#fffaf0',INK,3)
flag+=path('M 12 10 Q 22 5 30 7 L 30 22 Q 20 20 12 24 Z M 30 22 Q 40 24 48 26 L 48 41 Q 39 38 30 38 Z M 48 11 Q 57 14 64 10 L 64 24 Q 56 29 48 26 Z',INK,'none')
flag+=path('M 9 5 L 9 60','none',INK,4)
emit('ui_redesign/icons/finish_flag.png',72,64,flag)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Authored {len(manifest)} comic assets')
