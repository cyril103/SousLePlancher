"""Generate the review PDF from the maintained Markdown and CSV; no game files are modified."""
from pathlib import Path
import csv, re, html, json
from collections import Counter
from reportlab.pdfgen import canvas
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
                               PageBreak, Table, TableStyle, Image, KeepTogether)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.graphics.shapes import Drawing, Rect, Line, Polygon, String
from reportlab.lib.enums import TA_LEFT
from pypdf import PdfReader

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
OUT = ROOT / 'output' / 'pdf'
OUT.mkdir(parents=True, exist_ok=True)
PDF = OUT / 'Sous_le_plancher_Cahier_des_charges_v0.2.pdf'
for name, file in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Italic','calibrii.ttf'),('Light','calibril.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(Path('C:/Windows/Fonts')/file)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='Bold', italic='Italic', boldItalic='Bold')
INK=colors.HexColor('#213530'); GREEN=colors.HexColor('#2d6659'); GOLD=colors.HexColor('#ab8144')
PALE=colors.HexColor('#edf2ee'); GRAY=colors.HexColor('#5a6963'); LINE=colors.HexColor('#d4ded6')
W,H=595.276,841.89
FW=W-88

# The CSV is the maintained source of truth. PDF generation is read-only for it.
INVENTORY = BASE / 'inventaire-assets.csv'
with INVENTORY.open(encoding='utf-8-sig', newline='') as inventory_file:
    _rows = list(csv.reader(inventory_file, delimiter=';'))
if not _rows or any(len(row) != 10 for row in _rows):
    raise ValueError('Asset inventory must contain ten columns per row')
ASSETS = [tuple(row[:8]) for row in _rows[1:]]

def inventory():
    return INVENTORY

def rich(text):
    text=html.escape(text.strip())
    text=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',text)
    text=re.sub(r'`(.+?)`',r'<font color="#2d6659">\1</font>',text)
    return text

styles={
 'body':ParagraphStyle('Body',fontName='Body',fontSize=10.2,leading=14.1,textColor=INK,spaceAfter=8),
 'title':ParagraphStyle('Chapter',fontName='Bold',fontSize=23,leading=27,textColor=GREEN,spaceAfter=15,keepWithNext=True),
 'small':ParagraphStyle('Small',fontName='Body',fontSize=8.3,leading=10.5,textColor=GRAY,spaceAfter=5),
 'bullet':ParagraphStyle('Bullet',fontName='Body',fontSize=10.2,leading=14.1,textColor=INK,leftIndent=11,firstLineIndent=-9,spaceAfter=7),
 'cell':ParagraphStyle('Cell',fontName='Body',fontSize=8.8,leading=11.4,textColor=INK),
 'head':ParagraphStyle('CellHead',fontName='Bold',fontSize=8.8,leading=11.4,textColor=colors.white),
}

def box(d,x,y,w,h,title,lines=(),color=GREEN):
    d.add(Rect(x,y,w,h,rx=7,ry=7,fillColor=PALE,strokeColor=LINE,strokeWidth=.6))
    d.add(Rect(x,y+h-5,w,5,fillColor=color,strokeColor=None))
    d.add(String(x+9,y+h-21,title,fontName='Bold',fontSize=10,fillColor=color))
    for i,line in enumerate(lines): d.add(String(x+9,y+h-36-i*12,line,fontName='Body',fontSize=9,fillColor=INK))

def arrow(d,x1,y1,x2,y2):
    import math
    d.add(Line(x1,y1,x2,y2,strokeColor=GOLD,strokeWidth=1.4))
    a=math.atan2(y2-y1,x2-x1); r=5
    d.add(Polygon([x2,y2,x2-r*math.cos(a-.5),y2-r*math.sin(a-.5),x2-r*math.cos(a+.5),y2-r*math.sin(a+.5)],fillColor=GOLD,strokeColor=None))

def diagram(kind):
    d=Drawing(FW,192)
    if kind=='loop':
        labels=[('01 OBSERVER',['Lire les indices','Choisir le moment']),('02 EXPLORER',['Reconnaître un passage','Revenir avec une carte']),('03 AMÉNAGER',['Livrer puis construire','Ouvrir une route']),('06 CONSOLIDER',['Soigner et stocker','Préparer le prochain départ']),('05 EXPLOITER',['Transporter et produire','Maintenir les réserves']),('04 SÉCURISER',['Observer les menaces','Installer un refuge'])]
        for i,(title,lines) in enumerate(labels): box(d,(i%3)*173,105 if i<3 else 15,160,68,title,lines)
        for y in [139,49]:
            if y==139:
                arrow(d,161,y,173,y); arrow(d,334,y,346,y)
            else: arrow(d,173,y,161,y); arrow(d,346,y,334,y)
        arrow(d,426,104,426,84); arrow(d,80,83,80,103)
    elif kind=='house':
        box(d,178,133,160,52,'GRENIER',['Extension facultative'],GOLD)
        box(d,0,63,150,58,'SALON',['Départ / refuge / fibres'])
        box(d,178,63,160,58,'CLOISONS',['Conduits / eau / raccourcis'])
        box(d,366,63,140,58,'CUISINE',['Nourriture / fourmis'])
        box(d,178,0,160,49,'FONDATIONS',['Grand Refuge / rongeurs'])
        arrow(d,151,91,177,91); arrow(d,339,91,365,91); arrow(d,258,62,258,50);arrow(d,258,132,258,122)
        d.add(String(4,25,'Salle de bains : branche',fontName='Body',fontSize=9,fillColor=GRAY))
        d.add(String(4,12,'facultative depuis les cloisons.',fontName='Body',fontSize=9,fillColor=GRAY))
    elif kind=='slice':
        box(d,0,98,142,66,'REFUGE',['4 habitants','Stocks de départ'])
        box(d,182,98,142,66,'FISSURE',['Pont à construire','Contour à vide'])
        box(d,365,98,142,66,'CUISINE',['Biscuit','Piste de fourmis'])
        arrow(d,143,133,181,133);arrow(d,325,133,364,133)
        box(d,182,5,142,58,'DÉPÔT',['Réduit les transports'])
        arrow(d,435,97,324,35);arrow(d,181,35,71,97)
        d.add(String(3,67,'Reconnaissance puis',fontName='Body',fontSize=9,fillColor=GRAY))
        d.add(String(3,54,'livraison des matériaux',fontName='Body',fontSize=9,fillColor=GRAY))
        d.add(String(357,54,'Appât ou détour :',fontName='Body',fontSize=9,fillColor=GRAY))
        d.add(String(357,41,'choix du joueur',fontName='Body',fontSize=9,fillColor=GRAY))
    elif kind=='tasks':
        titles=['PROPOSÉE','RÉSERVÉE','TRAJET','TRAVAIL']
        for i,t in enumerate(titles):
            box(d,i*129,120,120,52,t,['Préconditions' if i==0 else ['','Stock + place','Chemin valide','Résultat unique'][i]])
            if i<3: arrow(d,i*129+121,145,i*129+128,145)
        box(d,0,12,155,62,'INTERROMPUE',['Libérer / protéger charge','Revalider la tâche'],GOLD)
        box(d,180,12,150,62,'IMPOSSIBLE',['Raison visible','Nouvel essai sur événement'],GOLD)
        box(d,357,12,150,62,'TERMINÉE',['Valider stock et travail','Libérer réservations'])
        arrow(d,180,119,76,75);arrow(d,278,119,253,75);arrow(d,447,119,430,75)
    elif kind=='navigation':
        box(d,0,113,158,63,'GRAPHE DE SECTEURS',['Quelle route choisir ?','Danger / coût / accès'])
        box(d,175,113,158,63,'CHEMIN LOCAL',['Surfaces praticables','Obstacles et évitement'])
        box(d,350,113,157,63,'LIEN SPÉCIAL',['Pont / échelle / conduit','Capacité et réservation'])
        arrow(d,159,145,174,145);arrow(d,334,145,349,145)
        box(d,89,13,330,64,'PASSAGE ÉTROIT',['Attente A -> réservation -> traversée -> sortie B','Une urgence peut être prioritaire, sans bloquer la file.'])
        arrow(d,427,112,366,78)
    elif kind=='architecture':
        box(d,0,119,151,60,'DÉFINITIONS',['Métiers / recettes / espèces','IDs et versions'])
        box(d,178,119,151,60,'SIMULATION',['Temps / tâches / stocks','Population / événements'])
        box(d,356,119,151,60,'PRÉSENTATION',['Scènes / UI / animations','Audio / effets'])
        arrow(d,152,148,177,148);arrow(d,330,148,355,148)
        box(d,0,14,151,62,'TESTS',['Règles et scénarios','Arènes de reproduction'])
        box(d,178,14,151,62,'SAUVEGARDE',['État versionné','Transactions et reprise'])
        box(d,356,14,151,62,'OUTILS DEBUG',['Chemins / perception','Réservations / budgets'])
        arrow(d,75,77,177,136);arrow(d,255,118,255,77);arrow(d,356,46,330,135)
    elif kind=='roadmap':
        titles=[('J0','Décisions'),('J1','Socle'),('J2','Travaux'),('J3','Cuisine'),('J4','Besoins'),('J5','Menaces'),('J6','Campagne'),('J7','Finition')]
        for i,(tag,title) in enumerate(titles):
            x=(i if i<4 else 7-i)*130; y=110 if i<4 else 15
            box(d,x,y,116,60,tag,[title],GOLD if i==3 else GREEN)
            if i<3: arrow(d,x+117,y+31,x+129,y+31)
            elif 4<=i<7: arrow(d,x-1,y+31,x-13,y+31)
        arrow(d,447,109,447,76)
        d.add(String(4,90,'J3 : décision de poursuivre, corriger ou réduire le périmètre.',fontName='Bold',fontSize=9.5,fillColor=GOLD))
    return d

class Dossier(BaseDocTemplate):
    def __init__(self,path):
        super().__init__(str(path),pagesize=(W,H),leftMargin=44,rightMargin=44,topMargin=55,bottomMargin=47,
                         title='Sous le plancher - Cahier des charges v0.2',author='Projet Sous le plancher',
                         subject='Conception, assets et roadmap - propositions à valider')
        frame=Frame(44,47,FW,H-102,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
        self.addPageTemplates(PageTemplate(id='main',frames=[frame],onPage=self.page))
        self.chapter_pages=[]
    def beforeDocument(self): self.chapter_pages=[]
    def page(self,c,doc):
        if doc.page==1: return
        c.saveState();c.setStrokeColor(LINE);c.setLineWidth(.5);c.line(44,H-35,W-44,H-35)
        c.setFont('Bold',8);c.setFillColor(GREEN);c.drawString(44,H-25,'SOUS LE PLANCHER')
        c.setFont('Body',8);c.setFillColor(GRAY);c.drawRightString(W-44,H-25,'CONCEPTION / v0.2 / À DISCUTER')
        c.line(44,35,W-44,35);c.drawString(44,23,'24 septembre 2026  |  Valeurs futures proposées, à tester')
        c.drawRightString(W-44,23,str(doc.page));c.restoreState()
    def afterFlowable(self,flow):
        if isinstance(flow,Paragraph) and flow.style.name=='Chapter':
            if flow.getPlainText()=='Parcours de lecture': return
            title=flow.getPlainText();key='chapter_'+str(len(self.chapter_pages))
            self.canv.bookmarkPage(key);self.canv.addOutlineEntry(title,key,0,False)
            self.notify('TOCEntry',(0,title,self.page,key));self.chapter_pages.append((title,self.page))

class Cover(Spacer):
    def __init__(self): super().__init__(1,H-105)
    def draw(self):
        c=self.canv
        c.saveState();c.setFillColor(colors.HexColor('#12251f'));c.rect(-44,-47,W,H,fill=1,stroke=0)
        c.setFillColor(colors.HexColor('#d7b77c'));c.setFont('Bold',12);c.drawString(0,680,'DOSSIER DE CONCEPTION  /  24.09.2026')
        c.setFillColor(colors.white);c.setFont('Light',42);c.drawString(0,608,'SOUS LE');c.drawString(0,561,'PLANCHER')
        c.setFont('Body',21);c.setFillColor(colors.HexColor('#d7b77c'));c.drawString(0,516,'Cahier des charges & roadmap')
        c.setFont('Body',12);c.setFillColor(colors.HexColor('#d2ded5'))
        c.drawString(0,481,'Une civilisation cachée. Une maison à découvrir.')
        img=ROOT/'artifacts'/'ambiance-finition.png'
        if img.exists(): c.drawImage(str(img),0,175,width=FW,height=FW*9/16,mask='auto')
        c.setFont('Body',8);c.setFillColor(colors.HexColor('#bacabd'));c.drawString(0,160,'Capture du prototype existant - ne représente pas les fonctionnalités futures.')
        c.setFont('Bold',12);c.setFillColor(colors.HexColor('#d7b77c'));c.drawString(0,112,'VERSION 0.2 - POUR RELECTURE ET DISCUSSION')
        c.setFont('Body',11);c.setFillColor(colors.white)
        c.drawString(0,86,'Gameplay · Habitants · IA · Carte · Assets · Production')
        c.drawString(0,62,'Propositions détaillées avant reprise du développement')
        c.restoreState()

def table(lines):
    rows=[]
    for line in lines:
        cells=[s.strip() for s in line.strip().strip('|').split('|')]
        if all(re.fullmatch(r'[:\- ]+',s) for s in cells): continue
        rows.append(cells)
    count=len(rows[0]); weights={3:[.22,.37,.41],4:[.21,.30,.30,.19],5:[.20,.13,.19,.13,.35]}.get(count,[1/count]*count)
    widths=[FW*x/sum(weights) for x in weights]
    data=[[Paragraph(rich(cell),styles['head' if i==0 else 'cell']) for cell in row] for i,row in enumerate(rows)]
    t=Table(data,colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),GREEN),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,PALE]),
                          ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),
                          ('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),
                          ('LINEBELOW',(0,-1),(-1,-1),.5,LINE)]))
    return [t,Spacer(1,10)]

def body_blocks(text):
    out=[]
    for block in re.split(r'\n\s*\n',text.strip()):
        if block.startswith('[[diagram:'):
            out.extend([diagram(block.split(':')[1].split(']')[0]),Spacer(1,10)])
        elif block.startswith('|'): out.extend(table(block.splitlines()))
        elif block.startswith('- '):
            for line in block.splitlines(): out.append(Paragraph('• '+rich(line[2:]),styles['bullet']))
        elif re.match(r'^\d+\. ',block):
            for line in block.splitlines(): out.append(Paragraph(rich(line),styles['bullet']))
        else: out.append(Paragraph(rich(block.replace('\n',' ')),styles['body']))
    return out

def main():
    inv=inventory()
    source=(BASE/'cahier-des-charges.md').read_text(encoding='utf-8-sig')
    sections=re.split(r'^## ',source,flags=re.M)[1:]
    story=[Cover(),PageBreak()]
    story.append(Paragraph('Parcours de lecture',styles['title']))
    story.append(Paragraph('35 fiches de conception, 7 schémas et un inventaire de %d lots. Commencer par les chapitres 01-06, puis revenir aux décisions du chapitre 32.'%len(ASSETS),styles['body']))
    toc=TableOfContents();toc.levelStyles=[ParagraphStyle('TOC',fontName='Body',fontSize=10,leading=15,textColor=INK,spaceBefore=2)]
    story.append(toc)
    for section in sections:
        title,body=section.split('\n',1)
        story.extend([PageBreak(),Paragraph(rich(title),styles['title']),*body_blocks(body)])
    # The CSV is the detailed inventory. Include a compact reference catalogue in PDF.
    story.extend([PageBreak(),Paragraph('36. Inventaire de production - catalogue',styles['title'])])
    counts=Counter(a[1] for a in ASSETS)
    story.append(Paragraph('Le fichier CSV associé contient les dépendances, livrables et critères de validation de chaque lot. Un lot peut contenir plusieurs modèles, états ou animations. P0 : indispensable à J0-J3 ; P1 : campagne de base ; P2 : secondaire ou option à confirmer.',styles['body']))
    story.append(Paragraph(' / '.join(f'{k} : {v} lots' for k,v in counts.items()),styles['small']))
    rows=['| ID | Lot et quantité | État / jalon |','| --- | --- | --- |']
    for a in ASSETS: rows.append(f'| {a[0]} | {a[2]} : {a[4]} | {a[3]} ; {a[5]} ; {a[6]} |')
    story.extend(table(rows))
    doc=Dossier(PDF);doc.multiBuild(story)
    reader=PdfReader(PDF)
    text='\n'.join(p.extract_text() for p in reader.pages)
    for section in sections:
        number=section.split('.',1)[0]
        assert number+'.' in text, number
    assert len(ASSETS)==len(set(a[0] for a in ASSETS))
    meta={'pages':len(reader.pages),'asset_lots':len(ASSETS),'chapters':doc.chapter_pages,
          'pdf':str(PDF),'inventory':str(inv),'characters':len(text)}
    (BASE/'validation-document.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(meta,ensure_ascii=False,indent=2))

if __name__=='__main__': main()
