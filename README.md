## Lancement

Vérifiez le fichier env.tcl en remplaçant FPGA_PART_NAME par votre modèle de FPGA.
Puis executez 

    source tcl/project.tcl

A l'intérieur de Vivado. Ceci devrait générer le projet et les IPs dans un dossier vivado/ à la racine.

## Génération des assets

Les assets générées sont fournies dans le dossier roms/

Si vous voulez modifier les assets, ou les regénérer, voici la procédure :

La génération des assets est gérée par le module Python situé dans le dossier "converter".
.... TODO

## Autres
### Codes clavier

Z : 0xF01D
Q : 0xF01C
S : 0xF01b
D : 0xF023


I : 0xF043
J : 0xF036
K : 0xF042
L : 0xF046

8 : 0xF06C
4 : 0xF071
5 : 0xF069
6 : 0xF07A

Up : 0xF075
Left : 0xF066
Down : 0xF072
Right : 0xF074