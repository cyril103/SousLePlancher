"""Build deterministic, editable sector maps and a standalone design atlas."""
from pathlib import Path
from html import escape as esc
import json
import textwrap

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/atlas-monde-v01'
DATA = json.loads((OUT / 'atlas.json').read_text(encoding='utf-8'))
MAPS = OUT / 'cartes'
MAPS.mkdir(exist_ok=True)
INK, MUTED, PAPER = '#282f2a', '#5f665d', '#f2eddf'
COLORS = {'partiel': '#37796b', 'prochain': '#b27727', 'campagne': '#9b692b', 'extension': '#776282'}
KINDS = {'Habitat': '#37796b', 'Ressource': '#986b23', 'Accès': '#416879', 'Danger': '#ae5046', 'Logistique': '#596b43', 'Observation': '#776282', 'Obstacle': '#66645e', 'Service': '#37796b'}

def txt(x, y, text, size=20, fill=INK, weight=400, anchor='start', family='Arial, sans-serif'):
    return f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{esc(str(text))}</text>'

def lines(x, y, text, width=43, size=18, fill=MUTED):
    return ''.join(txt(x, y+i*(size+8), line, size, fill) for i,line in enumerate(textwrap.wrap(text, width)))

def rect(x,y,w,h,fill=PAPER,stroke='#cec8b8',rx=8,extra=''):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" {extra}/>'

def route(points, color='#9b692b', dash='10 7', width=4):
    return f'<polyline points="{" ".join(f"{x},{y}" for x,y in points)}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="{dash}"/>'

def badge(x,y,label,color='#416879'):
    return rect(x-29,y-19,58,30,PAPER,color,5)+txt(x,y+3,label,17,color,700,'middle')

def start(title, subtitle, height=1060):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 {height}" role="img"><title>{esc(title)}</title><desc>{esc(subtitle)}</desc>',
    '<defs><pattern id="wood" width="150" height="72" patternUnits="userSpaceOnUse"><rect width="150" height="72" fill="#e7deca"/><path d="M0 71H150 M30 12H130 M8 25H75 M78 51H148" stroke="#cfc1a7" stroke-width="1"/></pattern><pattern id="danger" width="12" height="12" patternUnits="userSpaceOnUse"><path d="M-2 2L10 14 M2 -2L14 10" stroke="#ae5046" stroke-opacity=".28" stroke-width="2"/></pattern></defs>',
    rect(0,0,1600,height,PAPER,PAPER,0),txt(50,40,'SOUS LE PLANCHER  /  ATLAS DE CONCEPTION V01  /  25 SEPTEMBRE 2026',15,MUTED,700),
    txt(50,91,title,38,INK,400,family='Georgia, serif'),txt(50,126,subtitle,18,MUTED),
    '<path d="M50 147H1550" stroke="#b8af9b"/>']

def footer(svg, y=905, detailed=False):
    svg.append(txt(50,y,'LÉGENDE',16,MUTED,700))
    if detailed:
        for i,(kind,c) in enumerate(KINDS.items()):
            x=50+(i%4)*370; yy=y+35+(i//4)*35
            shape=rect(x,yy-9,18,18,c,c,3) if kind in ['Accès','Logistique','Habitat','Service'] else f'<circle cx="{x+9}" cy="{yy}" r="9" fill="{c}"/>'
            svg.append(shape)
            svg.append(txt(x+28,yy+6,kind+(' • zone hachurée' if kind=='Danger' else ''),18))
        svg.append(route([(50,y+103),(110,y+103)], '#37796b',''))
        svg.append(txt(125,y+109,'Circulation existante (salon) / proposée (autres plans)',17))
        svg.append(route([(760,y+103),(820,y+103)]))
        svg.append(txt(835,y+109,'Liaison à aménager / itinéraire alternatif',17))
    else:
        for i,(label,c,d) in enumerate([('Seuil existant • fonction partielle','#37796b',''),('Liaison de campagne proposée','#9b692b','10 7'),('Extension différée','#776282','3 9')]):
            x=50+i*500
            svg.append(route([(x,y+34),(x+65,y+34)],c,d))
            svg.append(txt(x+80,y+40,label,18))
    svg.append(txt(50,y+(153 if detailed else 119),'Carte de conception • tracés futurs à valider • aucune dimension physique définitive • pas une capture du jeu',16,MUTED))
    svg.append('</svg>')
    return ''.join(svg)

def overview():
    s=start('De la maison à la ville souterraine','Graphe déplié des secteurs : les lignes relient des seuils, elles ne représentent pas des couloirs à l’échelle.',1230)
    boxes={'S00':(90,300),'S01':(90,560),'S02':(490,560),'S03':(490,300),'S04':(900,560),'S05':(900,820),'E01':(1260,300),'E02':(900,170),'E03':(1260,820)}
    paths={
      'L01':([(230,430),(230,560)],(230,502)),
      'L02':([(370,625),(490,625)],(430,625)),
      'L03':([(370,365),(490,365)],(430,365)),
      'L04':([(630,560),(630,430)],(630,502)),
      'L05':([(770,395),(1040,395),(1040,560)],(1040,480)),
      'L06':([(770,625),(900,625)],(835,625)),
      'L07':([(1040,690),(1040,820)],(1040,760)),
      'L08':([(900,665),(840,665),(840,900),(900,900)],(840,760)),
      'L09':([(770,335),(1220,335),(1260,365)],(1130,335)),
      'L10':([(740,300),(740,235),(900,235)],(815,235)),
      'L11':([(1180,650),(1390,650),(1390,820)],(1390,746)),
      'L12':([(1390,950),(1390,1014)],(1390,987))}
    s += [rect(65,280,330,440,'#e2ebe1','#b6c6b5',18),txt(90,270,'SALON : S00 + SOUS-ZONE S01',15,'#37796b',700),txt(490,195,'CAMPAGNE ARTISANALE',17,MUTED,700),txt(1260,240,'EXTENSIONS DIFFÉRÉES',16,'#776282',700)]
    for link in DATA['links']:
        points,label=paths[link['id']]
        c='#37796b' if link['id']=='L01' else ('#776282' if link['status']=='Différé' else '#9b692b')
        s += [route(points,c,'' if link['id']=='L01' else ('3 9' if link['status']=='Différé' else '10 7')),badge(*label,link['id'],c)]
    for sec in DATA['sectors']:
        x,y=boxes[sec['id']];w=260 if sec['id'].startswith('E') else 280;c=COLORS[sec['status']]
        s += [f'<a href="../index.html#{sec["id"]}">',rect(x,y,w,130,'#faf7ed',c,10, 'stroke-width="2"'),txt(x+18,y+28,sec['id']+'  /  '+sec['level'],15,c,700)]
        phase='Après campagne • à cadrer' if sec['id']=='E03' else sec['phase']
        s += [lines(x+18,y+61,sec['short'],24,21,INK),txt(x+18,y+113,phase,15,MUTED),'</a>']
    s += [txt(90,776,'1. ÉTABLIR LE REFUGE',20,INK,700),txt(90,811,'2. TERMINER L’EXPÉDITION',20,INK,700),txt(90,846,'3. ATTEINDRE LA CUISINE',20,INK,700),txt(90,881,'4. PRÉPARER LA MIGRATION',20,INK,700),txt(90,916,'5. RENCONTRER LA VILLE',20,INK,700),txt(1390,1040,'Zones persistantes → …',18,'#776282',400,'middle')]
    return footer(s,1080)

POSITIONS=[(125,345),(325,345),(510,250),(780,250),(785,565),(525,565),(315,700),(125,700),(950,735),(905,360)]

def detailed(sec):
    s=start(sec['id']+' — '+sec['name'],sec['level']+'  /  '+sec['phase']+'  /  '+('Repères fixes du prototype ; accès L03 proposé.' if sec['id']=='S00' else 'Schéma d’implantation proposé : volumes et distances à éprouver dans Godot.'))
    s += [rect(50,175,960,650,'url(#wood)','#b8a98c',12),rect(1045,175,505,650,'#f8f4e9','#d2c9b6',12),txt(1070,211,'REPÈRES DU SECTEUR',18,MUTED,700)]
    if sec['id']=='S00':
        def proj(x,z):return (95+(x+10)*35,200+(z+8)*32)
        coordinates=[(-3,1),(-7,-4),(-7,3),(1,4),(4,-2),(7,2),(6,-3),(9.7,-5.5),(4,6.2),(-8,-6)]
        positions=[proj(*p) for p in coordinates]
        s += [rect(*proj(2.6,-6.6),330,125,'#d5dfdb','#8ba397'),txt(610,226,'PALIER • y ≈ 2,04',16,'#416879',700),rect(*proj(6.65,-6.6),94,125,'#a99f8a','#a99f8a',0),route([proj(6.65,-4),proj(9.35,-4)],'#37796b','',9),txt(515,793,'N conventionnel = −Z  •  Est = +X',16,MUTED)]
        s += [route([positions[0],proj(0,1),positions[6]],'#37796b',''),route([positions[0],proj(1,1),positions[8]],'#37796b',''),route([positions[6],proj(6,-4),proj(6.65,-4)],'#37796b',''),route([proj(9.35,-4),positions[7]],'#37796b',''),route([positions[0],positions[9]])]
        s.append(txt(80,854,'Positions X/Z relevées dans le code ; chemins schématiques. Mobilier placé par le joueur non représenté.',17,MUTED))
    else:
        positions=list(POSITIONS[:len(sec['points'])])
        if sec['id']=='S01': positions[5]=(535,390)
        special=sec['id'] in ['S03','S04','S05']
        if sec['id']=='S02':
            positions[2]=(780,250); positions[3]=(510,250)
            positions[5]=(890,405)
            s += [rect(680,190,235,110,'#ecdbaf','#b7a474',10),txt(690,320,'POCHE DE PROVISIONS',14,MUTED,700),rect(80,655,770,105,'#d7d5bd','#a7a688',8),txt(495,749,'PLINTHE • DÉTOUR COUVERT',15,MUTED),route([(480,185),(510,250),(680,295),(875,405)],'#ae5046','4 9',5),route([(785,565),(965,565),(965,250),(780,250)],'#37796b','')]
        if sec['id']=='S04':
            positions=[(125,345),(125,700),(510,250),(780,250),(785,565),(525,565),(750,700),(950,735),(905,360)]
            s += [rect(395,190,220,120,'#cbd8c5','#8fa384',8),txt(420,325,'IMPLANTATION SÈCHE',14,MUTED,700),rect(715,490,205,160,'#ccd7d4','#8ca9a7',10),txt(755,671,'BASSIN / FUITE',15,MUTED),rect(450,495,155,140,'url(#danger)','#ae5046',8)]
            s += [route([(125,345),(250,345),(250,250),(510,250)],'#37796b',''),route([(125,700),(325,700),(325,510),(370,510),(370,285),(510,250)],'#37796b',''),route([(510,250),(780,250),(905,360),(950,400),(950,700),(750,700)]),route([(370,510),(370,700),(650,750),(950,735)])]
        if sec['id']=='E01':
            s += [route([(510,185),(510,240),(565,340),(570,670)],'#87abaa','',36),txt(665,480,'ÉCOULEMENT',14,'#416879',700)]
        if sec['id']=='E02':
            s += [rect(90,420,850,55,'#b29a75','#8b7758',0),txt(90,455,'POUTRE PORTEUSE',14,'#493f32',700),rect(700,185,220,150,'url(#danger)','#ae5046',8)]
        if sec['id']=='E03':
            s += [rect(420,180,565,620,'#dde2c9','#adb693',15),txt(460,785,'TERRAIN GÉNÉRÉ • LIMITES INDICATIVES',15,MUTED,700)]
        if not special:
            s += [rect(420,345,235,100,'#b8a789','#9f8c6e',3),txt(537,372,'VOLUME NON PRATICABLE',13,'#554b3d',700,'middle')]
            s += [route([positions[0],positions[1],(340,250),positions[2],positions[3]],'#37796b','')]
            if sec['id']=='E01':
                s += [route([positions[1],(340,725),(925,725),(925,250),positions[3]]),route([(925,565),positions[4]],'#37796b','')]
            else:
                s += [route([positions[1],(340,510),(510,510),(785,510),positions[4]],'#37796b','')]
            if len(positions)>7:s.append(route([positions[4],(785,700),positions[6],positions[7]]))
            if len(positions)>8:s.append(route([positions[4],positions[8]]))
        if sec['id']=='S03':
            positions=[(125,345),(125,700),(355,510),(785,650),(785,250),(355,250),(585,740),(585,220)]
            for xx in [470,650]:
                for yy,hh in [(185,40),(275,210),(535,235)]: s.append(rect(xx,yy,50,hh,'#b09a79','#8b775b',2))
            s += [route([(585,220),(585,740)],'#416879','',6),route([(125,345),(355,345),(355,510),(585,510),(785,510),(785,650)],'#37796b',''),route([(125,700),(355,700),(355,510)],'#37796b',''),route([(355,250),(585,250),(785,250)])]
        if sec['id']=='S05':
            positions=[(125,345),(125,700),(525,485),(365,250),(790,250),(790,700),(330,590),(900,485)]
            for x,y,w,h,label in [(255,190,220,135,'ACCUEIL'),(685,190,230,135,'SAVOIR-FAIRE'),(685,630,230,130,'CONSEIL'),(250,530,175,135,'TRANSIT'),(820,410,155,155,'QUARTIERS')]:
                s += [rect(x,y,w,h,'#d5dfd0','#91a58b',9),txt(x+12,y+24,label,13,MUTED,700)]
            s += [f'<ellipse cx="525" cy="485" rx="110" ry="90" fill="#eddfbd" stroke="#b9a777"/>',route([(125,345),(220,345),(220,485),(525,485),(790,485),(900,485)],'#37796b',''),route([(125,700),(220,700),(220,590),(330,590),(525,590),(525,485)],'#37796b',''),route([(365,250),(525,250),(525,485),(790,485),(790,250)],'#37796b',''),route([(525,485),(525,700),(790,700)],'#37796b','')]
        caption='Colonne à paliers • traversées aménagées dans les montants' if sec['id']=='S03' else 'Contour de travail indicatif • passages repérés par leurs IDs Lxx'
        s += [txt(80,805,caption,17,MUTED)]
    for i,(letter,name,kind,desc) in enumerate(sec['points']):
        x,y=positions[i];c=KINDS[kind]
        if kind=='Danger':s += [rect(x-55,y-45,110,90,'url(#danger)','#ae5046',10)]
        shape=rect(x-20,y-20,40,40,c,c,5) if kind in ['Accès','Logistique','Habitat','Service'] else f'<circle cx="{x}" cy="{y}" r="21" fill="{c}"/>'
        s += [f'<g><title>{esc(name+" — "+desc)}</title>',shape,txt(x,y+7,letter,22,'#fffaf0',700,'middle'),'</g>']
        yy=247+i*55
        s += [txt(1070,yy,letter,22,c,700),txt(1103,yy,name,18,INK,700),txt(1103,yy+22,kind,15,c)]
    return footer(s,885,True)

def section():
    s=start('La maison en coupe','Niveaux topologiques de conception ; hauteurs non cotées. Les volumes de la maison ne sont pas des secteurs jouables entiers.')
    bands=[(190,'N+2','Grenier • E02 • différé','#e9e0dc'),(310,'N+1','Cloisons hautes • S03','#e4e4d9'),(430,'N0','Salon + alcôve + cuisine • S00 / S01 / S02','#e5dec9'),(580,'N−1','Fondations • S04 • Grand Refuge','#dbe2db'),(730,'N−2','Ville indépendante • S05','#dbe1e5')]
    for y,n,label,c in bands:
        s += [rect(190,y,1130,95,c,'#c3bcaa',5),txt(65,y+49,n,27,INK,700),txt(220,y+38,label,23),txt(220,y+69,'Campagne prévue' if n not in ['N+2','N0'] else ('Extension future' if n=='N+2' else 'Prototype partiel dans le salon'),16,MUTED)]
    s += [route([(1120,235),(1120,355)],'#776282','3 9'),txt(1140,285,'L10',17,'#776282',700),route([(1120,355),(1120,625)]),txt(1140,400,'L05',17,'#9b692b',700),route([(1120,625),(1120,775)]),txt(1140,699,'L07 / L08',17,'#9b692b',700),route([(985,475),(985,625)]),txt(910,558,'L06',17,'#9b692b',700),txt(1350,448,'Maison',18),txt(1350,476,'humaine',18),txt(1350,629,'L11 →',19,'#776282'),txt(1350,656,'extérieur',18,'#776282'),txt(220,515,'E01 salle de bains : branche différée au niveau de la gaine',15,'#776282'),txt(220,855,'Palier du salon : y ≈ 2,04 unités Godot ; ce dénivelé local ne correspond pas à l’étage N+1 de la maison.',18,MUTED)]
    return footer(s,905)

def write_maps():
    (MAPS/'00-vue-ensemble.svg').write_text(overview(),encoding='utf-8')
    (MAPS/'01-coupe-verticale.svg').write_text(section(),encoding='utf-8')
    for sec in DATA['sectors']:(MAPS/f'{sec["id"]}.svg').write_text(detailed(sec),encoding='utf-8')

def paragraph(label,text):return f'<p><strong>{label}</strong> {esc(text)}</p>'

def build_html():
    navigation='<button data-view="ensemble" aria-pressed="true">Vue d’ensemble</button><button data-view="coupe" aria-pressed="false">Coupe verticale</button>'+''.join(f'<button data-view="{s["id"]}" aria-pressed="false">{s["id"]} · {esc(s["name"])}</button>' for s in DATA['sectors'])
    table='<table><thead><tr><th>Accès</th><th>Liaison</th><th>État / étape</th><th>Conditions</th></tr></thead><tbody>'+''.join(f'<tr><td><b>{l["id"]}</b><br>{esc(l["name"])}</td><td>{l["from"]} ↔ {l["to"]}<br>{esc(l["level"])}</td><td>{esc(l["status"])}<br>{esc(l["phase"])}</td><td>{esc(l["rule"])}</td></tr>' for l in DATA['links'])+'</tbody></table>'
    sections=''
    for sec in DATA['sectors']:
        points=''.join(f'<tr><td><b>{p[0]}</b></td><td>{esc(p[1])}<br><small>{p[2]}</small></td><td>{esc(p[3])}</td></tr>' for p in sec['points'])
        facts=''.join(paragraph(label,sec[key]) for label,key in [('Rôle.','role'),('Ressources.','resources'),('Dangers.','danger'),('Aménagements.','build'),('Objectif.','goal'),('Retour et secours.','return'),('Variations entre parties.','variation')])
        sections+=f'<section id="{sec["id"]}" class="sheet" hidden><h2>{sec["id"]} · {esc(sec["name"])}</h2><p class="eyebrow">{esc(sec["level"])} · {esc(sec["phase"])}</p><a class="original" href="cartes/{sec["id"]}.svg" target="_blank">Ouvrir le plan vectoriel en grand ↗</a><img src="cartes/{sec["id"]}.svg" alt="Plan détaillé {esc(sec["name"])} avec repères et légende"><div class="facts">{facts}</div><h3>Repères et usages</h3><table><thead><tr><th>Repère</th><th>Lieu</th><th>Fonction et limites</th></tr></thead><tbody>{points}</tbody></table></section>'
    css='''*{box-sizing:border-box}body{margin:0;background:#f2eddf;color:#282f2a;font:16px/1.65 Arial,sans-serif}header,main,footer{max-width:1520px;margin:auto;padding:30px 40px}header{padding-top:45px;border-bottom:1px solid #c4bba7}.eyebrow{font-size:12px;font-weight:bold;letter-spacing:.15em;text-transform:uppercase;color:#646b60}h1{font:50px/1.1 Georgia,serif;margin:15px 0}h2{font:34px/1.2 Georgia,serif}h3{font:25px Georgia,serif}.lead{max-width:980px;font-size:18px}nav{display:flex;gap:8px;flex-wrap:wrap;margin:22px 0}button{background:transparent;color:#354338;border:1px solid #b4b6a4;border-radius:5px;padding:11px 15px;font:inherit;cursor:pointer}button[aria-pressed=true]{background:#344a3e;color:#fff9e8;border-color:#344a3e}button:focus-visible,a:focus-visible{outline:3px solid #b7772b;outline-offset:4px}a{color:#416879}img{width:100%;display:block;margin:18px 0 26px}.original{font-size:14px}table{border-collapse:collapse;width:100%;font-size:15px}td,th{padding:13px 14px;text-align:left;vertical-align:top;border-bottom:1px solid #ccc3af}th{background:#e3ddcd}small{color:#616959}.facts{columns:2;column-gap:46px}.facts p{break-inside:avoid;margin:0 0 16px}.note{border-left:4px solid #aa772c;padding:12px 20px;background:#e9e0ce;margin:25px 0}.sheet[hidden]{display:none}footer{border-top:1px solid #c4bba7;font-size:14px}.actions{display:flex;gap:16px;flex-wrap:wrap} @media(max-width:760px){header,main,footer{padding:22px 16px}h1{font-size:36px}.facts{columns:1}table{font-size:13px}td,th{padding:9px 5px}nav button{font-size:14px;padding:9px}img{margin:12px 0}} @media print{body{background:white}nav,.actions,.original,footer{display:none!important}.sheet[hidden]{display:block!important}.sheet{break-before:page}header,main{padding:0}img{max-height:175mm;object-fit:contain}table{font-size:10pt}tr{break-inside:avoid}.facts{font-size:11pt}h1{font-size:30pt}@page{size:A3 landscape;margin:14mm}'''
    script='''const buttons=[...document.querySelectorAll('nav button')], panels=[...document.querySelectorAll('.sheet')];function show(id){if(!panels.some(p=>p.id===id))id='ensemble';panels.forEach(p=>p.hidden=p.id!==id);buttons.forEach(b=>b.setAttribute('aria-pressed',b.dataset.view===id));}buttons.forEach(b=>b.addEventListener('click',()=>{location.hash=b.dataset.view;show(b.dataset.view)}));addEventListener('hashchange',()=>show(location.hash.slice(1)));show(location.hash.slice(1)||'ensemble');document.getElementById('print').addEventListener('click',()=>window.print());'''
    return f'''<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sous le Plancher — Atlas du monde V01</title><style>{css}</style></head><body><header><p class="eyebrow">Sous le Plancher / Direction du monde / 25 septembre 2026</p><h1>Une maison au-dessus.<br>Un monde à relier en dessous.</h1><p class="lead">Plan de campagne détaillé : quatre grands milieux de la maison, une alcôve d’apprentissage et une ville indépendante. Les extensions restent séparées du prochain chantier.</p><div class="actions"><a href="README.md">Dossier de conception</a><a href="atlas.json">Données des secteurs</a><button id="print">Imprimer l’atlas complet</button></div></header><main><nav aria-label="Choisir une carte">{navigation}</nav><section id="ensemble" class="sheet"><h2>Carte d’ensemble</h2><p>Vue dépliée des connexions. Chaque liaison est réversible après aménagement, sous réserve des restrictions de charge et des dangers locaux.</p><a class="original" href="cartes/00-vue-ensemble.svg" target="_blank">Ouvrir la carte vectorielle en grand ↗</a><img src="cartes/00-vue-ensemble.svg" alt="Carte de tous les secteurs avec liaisons L01 à L12"><div class="note"><b>Lecture de l’état actuel.</b> Seul le salon est largement jouable. L’alcôve existe pour une visite à vide ; son extension et l’expédition équipée restent à faire. Les autres tracés sont proposés. Le palier Est n’est pas la cuisine. Ni la salle de bains ni le grenier ne sont nécessaires à la campagne principale.</div><h3>Registre des passages</h3>{table}</section><section id="coupe" class="sheet" hidden><h2>Comprendre les niveaux</h2><a class="original" href="cartes/01-coupe-verticale.svg" target="_blank">Ouvrir la coupe en grand ↗</a><img src="cartes/01-coupe-verticale.svg" alt="Coupe verticale de la maison jusqu’à la ville"><p>Les niveaux N désignent des strates de conception, pas des coordonnées Godot. Le palier actuel à y ≈ 2,04 reste un relief local du salon. Les liaisons verticales devront avoir leurs propres files, points d’appui et restrictions de charge.</p></section>{sections}</main><footer>V01 proposée • Base publiée ec1214c • Géométrie future à valider • <a href="../conception/roadmap-production.md">Roadmap de production</a> • Images vectorielles et données conservées dans le projet, sans modification du jeu.</footer><script>{script}</script></body></html>'''

if __name__=='__main__':
    write_maps()
    (OUT/'index.html').write_text(build_html(),encoding='utf-8')
    print('Atlas built: 11 SVG maps, 9 sector sheets, 12 passage records.')
