"""Generate the review PDF and production inventory; no game files are modified."""
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
PDF = OUT / 'Sous_le_plancher_Cahier_des_charges_v0.1.pdf'
for name, file in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Italic','calibrii.ttf'),('Light','calibril.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(Path('C:/Windows/Fonts')/file)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='Bold', italic='Italic', boldItalic='Bold')
INK=colors.HexColor('#213530'); GREEN=colors.HexColor('#2d6659'); GOLD=colors.HexColor('#ab8144')
PALE=colors.HexColor('#edf2ee'); GRAY=colors.HexColor('#5a6963'); LINE=colors.HexColor('#d4ded6')
W,H=595.276,841.89
FW=W-88

ASSETS = [
('CHR-01','Personnages','Habitant de référence et rig','Prototype à remplacer','1 corps + 1 rig + 3 visages','J0-J2','P0','Échelle, capsule, points main/dos/tête'),
('CHR-02','Personnages','Variantes de métiers','À créer','6 palettes + 4 accessoires + 3 sacs','J3-J4','P1','Rig CHR-01 ; silhouettes distinctes'),
('CHR-03','Personnages','Locomotion','À créer','5 animations + transitions','J2','P0','Rig et vitesse réelle de navigation'),
('CHR-04','Personnages','Travail et manipulation','À créer','5 animations interruptibles','J2-J3','P0','Contrat de tâches et attaches de charge'),
('CHR-05','Personnages','Besoins, blessures et danger','À créer','7 animations + transitions','J4-J5','P1','Besoins, soin et règles de mortalité'),
('CHR-06','Personnages','Traversées et entraide','À créer','4 séquences','J3-J5','P1','Liens de navigation et coordination à deux'),
('FAU-01','Faune','Fourmi','À créer','1 rig + 2 variantes + 5 actions','J3','P0','Piste, transport et défense locale'),
('FAU-02','Faune','Araignée','À créer','1 rig + 2 tailles + 5 actions','J5','P1','Toile active et perception vibratoire'),
('FAU-03','Faune','Souris','À créer','1 rig + 2 matières + 6 actions','J5','P1','Territoire, reniflement et fuite'),
('FAU-04','Faune','Rat','À créer','1 variante adaptée + 6 actions','J6','P2','Fonction différente de la souris à valider'),
('FAU-05','Faune','Cloporte et cafard','Option à confirmer','2 rigs + 4 actions chacun','J6+','P2','Humidité et pillage ; priorité après J3'),
('ENV-01','Environnement','Kit bois sous-plancher','Prototype à reprendre','6 planches + 3 poutres','J0-J3','P0','Scène étalon, UV et usure'),
('ENV-02','Environnement','Fondations et raccords','Prototype à reprendre','4 murs/angles + 2 jonctions','J3-J6','P1','Connexion à ENV-01 et passages'),
('ENV-03','Environnement','Cuisine miniature','À créer','3 modules + 6 accessoires','J3','P0','Géométrie de la première aventure'),
('ENV-04','Environnement','Cloisons et conduits','À créer','4 modules + 4 intersections','J4-J6','P1','Entrées nommées et liens verticaux'),
('ENV-05','Environnement','Cave et Grand Refuge','À créer','4 modules + 2 sites','J6','P1','Objectifs de campagne et rat éventuel'),
('ENV-06','Environnement','Salle de bains','Option à confirmer','3 modules + 4 accessoires','Après J6','P2','Campagne étendue, eau et fuite'),
('ENV-07','Environnement','Grenier','Option à confirmer','3 modules + 4 accessoires','Après J6','P2','Campagne étendue et sécheresse'),
('BLD-01','Bâtiments','Refuge initial','Prototype à reprendre','1 bâtiment / 4 états','J2','P0','Stocks, lits et sorties'),
('BLD-02','Bâtiments','Abri','Prototype à reprendre','1 bâtiment / 4 états','J2','P0','2 lits, chantier, arrivée non instantanée'),
('BLD-03','Bâtiments','Atelier','Prototype à reprendre','1 bâtiment / 4 états','J2-J4','P0','Poste artisan et files'),
('BLD-04','Bâtiments','Dépôt intermédiaire','À créer','1 bâtiment / 4 états','J3','P0','12 emplacements et filtres'),
('BLD-05','Bâtiments','Pont en allumettes','À créer','3 longueurs / 4 états','J2-J3','P0','Réservation de passage et accès chantier'),
('BLD-06','Bâtiments','Échelle','À créer','2 hauteurs / 4 états','J3-J4','P1','Animation de montée et capacité du lien'),
('BLD-07','Bâtiments','Étai','À créer','2 variantes / 4 états','J4','P1','Intégrité de passage fragile'),
('BLD-08','Bâtiments','Collecteur eau','À créer','1 bâtiment / 4 états','J4','P1','Source active, débit et réservoir'),
('BLD-09','Bâtiments','Infirmerie','À créer','1 bâtiment / 4 états','J4','P1','Lit, soins et animation de transport'),
('BLD-10','Bâtiments','Poste de veille','À créer','1 bâtiment / 4 états','J5','P1','Champ de vision et observation'),
('BLD-11','Bâtiments','Table préparation repas','À créer','1 bâtiment / 4 états','J4','P1','Recettes et représentation des stocks'),
('BLD-12','Bâtiments','Bac de culture','À créer','1 bac / 3 croissances / dégâts','J6','P2','Eau, humidité, rendement'),
('BLD-13','Bâtiments','Porte camouflée','À créer','2 variantes / ouverte-fermée','J5','P1','Navigation, odeur, visibilité'),
('BLD-14','Bâtiments','Gouttière','À créer','3 segments + raccord','J5','P2','Volumes de fuite et écoulement'),
('BLD-15','Bâtiments','Grand Refuge','À créer','1 ensemble / 4 états','J6','P1','Lits, 2 accès, victoire et évacuation'),
('PRP-01','Objets','Nourriture et biscuit','Prototype à reprendre','3 tas + biscuit + charge','J3','P0','Quantité restante visible'),
('PRP-02','Objets','Bois récoltable','Prototype à reprendre','3 tas + charge','J2','P0','Volume de stockage'),
('PRP-03','Objets','Fibres récoltables','Prototype à reprendre','3 tas + charge','J2','P0','Volume de stockage'),
('PRP-04','Objets','Eau et récipients','À créer','3 niveaux + charge','J4','P1','Lisibilité de quantité et qualité'),
('PRP-05','Objets','Métal récupéré','À créer','3 tas + charge','J4','P1','Agrafes, trombone, outils'),
('PRP-06','Objets','Résine','À créer','2 tas + charge','J5','P2','Recette étanchéité'),
('PRP-07','Objets','Soie récoltable','À créer','2 tas + charge','J5','P1','Différente des toiles fonctionnelles'),
('PRP-08','Objets','Déchets et accessoires','Prototype à reprendre','12 objets, variantes usuelles','J3-J6','P1','Instanciation et composition'),
('PRP-09','Objets','Outils et bandages','À créer','4 outils + 1 bandage','J4','P1','Attaches mains/dos et recette'),
('PRP-10','Objets','Appâts','À créer','2 types / 3 états','J3-J5','P0','Attraction et consommation visibles'),
('PRP-11','Objets','Charges portées','À créer','8 catégories liées aux ressources','J2-J5','P0','Rig, emplacements et absence de clipping'),
('PRP-12','Objets','Conteneurs','À créer','3 tailles / 3 niveaux','J3-J4','P1','Filtres de réserve et inventaire'),
('PRP-13','Objets','Indices exploration','À créer','6 traces / variantes','J3-J5','P1','Odeurs figurées, griffures, fuites'),
('VFX-01','Effets','Torche, flamme et braises','Prototype à affiner','1 ensemble / 3 intensités','J0-J3','P0','Source Blender, lumière et budget ombres'),
('VFX-02','Effets','Lumière entre planches','Prototype à affiner','3 profils distincts','J0-J3','P0','Profondeur, rotation, réglage réduit'),
('VFX-03','Effets','Poussière en suspension','Prototype à affiner','2 densités + 1 variante chantier','J0-J3','P0','Lisibilité sans effet de neige'),
('VFX-04','Effets','Toiles','Prototype décoratif à étendre','2 décoratives + 1 active déchirable','J0-J5','P1','Fil fonctionnel signalé, mode arachnophobie'),
('VFX-05','Effets','Fuite et eau','À créer','Filet, impact, sol humide','J4-J5','P1','Volume dangereux synchronisé'),
('VFX-06','Effets','Passage humain','Prototype partiel','Ombre, secousse, aspiration','J5','P1','Réglage accessibilité et signaux'),
('VFX-07','Effets','Travaux','À créer','3 petits effets','J2-J3','P1','Animation et production de bruit'),
('VFX-08','Effets','Humidité locale','Option à confirmer','1 effet léger','J6','P2','Budget transparent et visibilité'),
('UI-01','Interface','Barre et pictogrammes','Prototype à compléter','12-16 pictogrammes','J1-J4','P0','Échelles UI et texte de remplacement'),
('UI-02','Interface','Portraits et états','À créer','6 portraits + 10 états','J4','P1','Identité et besoins sans couleur seule'),
('UI-03','Interface','Carte et niveaux','À créer','1 vue + 8 symboles','J3-J6','P0','Inconnu, mémorisé, observé'),
('UI-04','Interface','Panneaux gestion','Prototype partiel','8 vues','J1-J6','P0','Stocks, métiers, chantiers, réglages'),
('UI-05','Interface','Alertes et journal','Prototype à reprendre','3 sévérités + historique','J2-J5','P0','Cause, action et centrage'),
('UI-06','Interface','Tutoriel et fin','Prototype à reprendre','6 étapes + bilan final','J3-J6','P1','Pas de guidage oral requis'),
('AUD-01','Audio','Ambiances de secteur','À créer','4 boucles','J3-J6','P1','Licence et transitions'),
('AUD-02','Audio','Humains','À créer','6 prises de pas + 3 événements','J3-J5','P0','Correspondance calendrier et sous-titres'),
('AUD-03','Audio','Travaux et portage','À créer','8 familles x 3 variantes','J2-J4','P1','Limite de voix simultanées'),
('AUD-04','Audio','Faune','À créer','4 familles','J3-J6','P1','Perception et discrétion'),
('AUD-05','Audio','Interface','À créer','8 sons courts','J3','P1','Volume séparé et priorité'),
('AUD-06','Audio','Musique','À créer','2 thèmes/textures','J6-J7','P2','Pas de révélation involontaire du danger'),
]

def inventory():
    path=BASE/'inventaire-assets.csv'
    fields=['ID','Famille','Lot','Statut actuel','Quantité / variantes','Jalon','Priorité','Dépendances et usage','Livrables attendus','Validation']
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.writer(f,delimiter=';'); w.writerow(fields)
        for row in ASSETS:
            family=row[1]
            if family in ['Personnages','Faune']:
                deliver='Source Blender ; GLB ; rig ; clips ; textures ; LOD ; attaches ; licence'
                test='Échelle, transitions et silhouette validées ; pas de glissement de pieds ; intégration navigation'
            elif family in ['Environnement','Bâtiments','Objets']:
                deliver='Source Blender ; GLB ; textures ; collisions utiles ; points interaction ; variantes ; licence'
                test='Échelle et pivots ; UV ; collision ; accès ; états ; coût mesuré dans scène étalon'
            elif family=='Effets':
                deliver='Scène Godot ; shader ; textures éventuelles ; paramètres ; profil réduit'
                test='Caméra normale, rotation et gros plan ; pas de scintillement ; effet stoppé aux obstacles'
            elif family=='Interface':
                deliver='Sources vectorielles ; exports ; scène UI ; états ; textes et infobulles'
                test='1280x800 et 1920x1080 ; UI agrandie ; contraste ; clavier ; aucune commande perdue'
            else:
                deliver='Sources autorisées ; WAV de travail ; OGG export ; licence ; volumes et variations'
                test='Pas de raccord ni saturation ; variantes ; volume séparé ; signal équivalent sans son'
            w.writerow([*row,deliver,test])
    return path

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
                         title='Sous le plancher - Cahier des charges v0.1',author='Projet Sous le plancher',
                         subject='Conception, assets et roadmap - propositions à valider')
        frame=Frame(44,47,FW,H-102,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
        self.addPageTemplates(PageTemplate(id='main',frames=[frame],onPage=self.page))
        self.chapter_pages=[]
    def beforeDocument(self): self.chapter_pages=[]
    def page(self,c,doc):
        if doc.page==1: return
        c.saveState();c.setStrokeColor(LINE);c.setLineWidth(.5);c.line(44,H-35,W-44,H-35)
        c.setFont('Bold',8);c.setFillColor(GREEN);c.drawString(44,H-25,'SOUS LE PLANCHER')
        c.setFont('Body',8);c.setFillColor(GRAY);c.drawRightString(W-44,H-25,'CONCEPTION / v0.1 / À DISCUTER')
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
        c.setFont('Bold',12);c.setFillColor(colors.HexColor('#d7b77c'));c.drawString(0,112,'VERSION 0.1 - POUR RELECTURE ET DISCUSSION')
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
