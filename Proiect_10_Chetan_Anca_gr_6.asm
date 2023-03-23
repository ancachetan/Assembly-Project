.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem msvcrt.lib, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern printf: proc
extern fscanf: proc
extern fopen: proc
extern fclose: proc
extern scanf: proc
extern fprintf: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
sir dd 100 dup(0)						;in acest sir retinem toate numerele din fisierul numere.txt
lgsir dd 0								;in lgsir retinem numarul de elemente din sir 
x dd 0
min dd 0								;in min se retine minimul din sir
max dd 0								;in max se retine maximul din sir 
media dq 0								;in media se retine media bazata pe histograma 
deviatie dq 0							;in deviatie se retine deviatia calculata cu ajutorul mediei 
suma dq 0
val_inf dd 0							;val_inf retine valoarea 2 * deviatie
val_sup dd 0							;val_sup retine valoarea (-2) * deviatie
doi dd 2
minus_2 dd -2
suma_medie dd 0


histograma_numere dd 100 dup(0)			;in vectorul histograma_numere se retin frecventele de aparitie a tuturor elementelor din fisierul numere.txt
;la pozitia i se afla elementul n in sirul sir_numere si in sirul histograma_numere tot la pozitia i frecventa de aparitie a lui n in fisierul numere.txt
sir_numere dd 100 dup(0)				;in sir_numere se retin numerele din sirul sir dar fara a aparea duplicate
lgsir_numere dd 0						;numarul de elemenente din sir_numere si histograma_numere

fisier_numere db "numere.txt", 0
fisier_histograma db "histograma.txt", 0
fisier_medie db "media.txt", 0
fisier_minim_maxim db "minmax.txt", 0
fisier_deviatie db "deviatie.txt", 0
fisier_eliminare db "eliminareinterval.txt", 0

mod_scriere db "w", 0
mod_citire db "r", 0

format_intreg db "%d ", 0
format_intregi db "%d %d ", 0 
format_real db "%lf ", 0 
format_intreg_citire db "%d", 0        						

mesaj_inceput db "Incarcare fisier: ", 13, 10, 0
new_line db " ", 13, 10, 0
mesaj_minim db "min = ", 0
mesaj_maxim db "max = ", 0 
mesaj_salvat db "Salvat in ", 0
mesaj_optiuni db "Selecteaza optiunea", 13, 10, 0
optiune1 db "1.Histograma", 13, 10, 0
optiune2 db "2.Calculul mediei", 13, 10, 0
optiune3 db "3.Calculul deviatiei standard", 13, 10, 0
optiune4 db "4.Eliminare valori", 13, 10, 0
mesaj_exit db "5.Exit", 13, 10, 0
mesaj_alegere_optiune db "Alege optiune: ", 0
mesaj_optiune_neexistenta db "Optiunea aleasa nu exista!!!", 13, 10, 0
mesaj_optiune_1 db "1 numere.txt", 13, 10, 0
mesaj_optiune_2 db "2 histograma.txt", 13, 10, 0
mesaj_optiune_3 db "3 media.txt", 13, 10, 0
mesaj_optiune_4 db "1 numere.txt", 13, 10, 0

optiune dd 0									;optiunea aleasa de utilizator 

.code

cautare_minim PROC ;conventia cdecl
	push EBP
	mov EBP, ESP				;pregatim stack frame-ul 
	
	mov ECX, [EBP + 8]			;in ECX avem lungimea sirului
	mov EDI, [EBP + 12]			;in EDI avem adresa sirului
	
	mov EDX, 0					;cu EDX ne deplasam prin sir 
	mov EAX, [EDI][EDX]			;in EAX vom calcula minimul pe care il initializam cu prima valoare din sir 
	add EDX, 4					;incepem cautarea minimului de la al doilea numar din sir
	minim:
		cmp [EDI][EDX], EAX		;comparam minimul actual cu fiecare element din sir 
		jl e_mai_mic			;daca elementul la care ne aflam acum e mai mic decat EAX actualizam registrul EAX
		jmp fin
		e_mai_mic:
			mov EAX, [EDI][EDX]
		fin:
			add EDX, 4			;trecem la urmatorul element din sir 
	loop minim
	final: 
		mov ESP, EBP
		pop EBP
		ret
cautare_minim ENDP
	
cautare_maxim PROC ;conventia cdecl
	push EBP
	mov EBP, ESP				;pregatim stack frame-ul 
	
	mov ECX, [EBP + 8]			;in ECX avem lungimea sirului
	mov EDI, [EBP + 12]			;in EDI avem adresa sirului
	
	mov EDX, 0					;cu EDX ne deplasam prin sir 
	mov EAX, [EDI][EDX]			;in EAX vom calcula maximul pe care il initializam cu primul element din sir
	add EDX, 4					;incepem cautarea maximului de la al doilea numar din sir
	maxim:
		cmp [EDI][EDX], EAX		;comparam maximul actual cu fiecare element din sir
		jg e_mai_mare			;daca elementul la care ne aflam acum e mai mare decat EAX actualizam registrul EAX
		jmp fin
		e_mai_mare:
			mov EAX, [EDI][EDX]
		fin:
			add EDX, 4			;trecem la urmatorul element din sir 
	loop maxim
	final: 
		mov ESP, EBP
		pop EBP
		ret
cautare_maxim ENDP


cautare_element_sir PROC ;conventia cdecl
	push EBP
	mov EBP, ESP			;pregatim stack frame-ul
	
	mov EBX, [EBP + 8]		;in EBX avem elementul pe care il cautam in sir
	mov ECX, [EBP + 12]		;in ECX avem nr. de elemente din sir
	mov EDI, [EBP + 16]		;in EDI avem adresa sirului
	
	mov EAX, 0				;in EAX verficam daca gasim numarul in sir; EAX = 0 daca numarul nu a fost gasit si EAX = 1 daca s-a gasit numarul
	mov EDX, 0				;cu EDX ne deplasam prin sir
	cmp ECX, EDX			;daca vectorul este gol nu mai are sens cautarea si trecem direct la final
	je final
	cautare:
		cmp EBX, [EDI][EDX]	;comparam numarul cautat cu pe rand cu elementele din sir 
		je gasit			;daca sunt egale sarim la gasit 
		jmp fin
		gasit:
			mov EAX, 1		;semnalam ca am gasit numarul in sir prin EAX = 1 
			jmp final		;sarim la final deoarece nu mai are sens sa continuam cautarea
		fin:
			add EDX, 4		;trecem la urmatorul element din sir 
	loop cautare
	final: 
		mov ESP, EBP
		pop EBP
		ret
cautare_element_sir ENDP

numar_aparitii_element_sir PROC;conventia cdecl
	push EBP
	mov EBP, ESP			;pregatim stack frame-ul
	
	mov EBX, [EBP + 8]		;in EBX avem elementul pe care il cautam in sir 
	mov ECX, [EBP + 12]		;in ECX avem numarul de elemente din sir 
	mov EDI, [EBP + 16]		;in EDI avem adresa sirului 
	
	mov EDX, 0				;cu EDX ne deplasam prin sir
	mov EAX, 0				;in EAX calculam numarul de aparitii ale elementului, pastrat in EBX, in sir 
	cautare:
		cmp EBX, [EDI][EDX]	;comparam fiecare element din sir cu EBX 
		je numarare	
		jmp fin				
		numarare:
			inc EAX			;daca sunt egale incrementam contorul EAX
		fin:
			add EDX, 4		;trecem la urmatorul element din sir 
	loop cautare 
	final: 
		mov ESP, EBP
		pop EBP
		ret
numar_aparitii_element_sir ENDP

afisare_sir_fisier PROC ;cdecl
	push EBP
	mov EBP, ESP			;pregatim stack frame-ul
	
	mov ECX, [EBP + 8]		;in ECX avem lungimea sirului
	mov ESI, [EBP + 12]		;in ESI avem pointer catre fisierul in care se face scrierea
	mov EDI, [EBP + 16]		;in EDI avem adresa sirului
	mov EBX, [EBP + 20]		;in EBX avem adresa formatului de scriere
	
	mov EDX, 0				;cu EDX ne deplasam prin sir
	afisare_sir:
		push ECX			;punem registrii folositi in procedura pe stiva pentru a nu fi modicficati dua ce apelam fprintf 
		push EDX
		push EBX
		
		push [EDI][EDX]		;afisam cate un numar pe rand 
		push EBX
		push ESI
		call fprintf
		add ESP, 12
		
		pop EBX				;recuperam registrii de pe stiva 
		pop EDX
		pop ECX
		
		add EDX, 4			;trecem la urmatorul element 
	loop afisare_sir
	
	final: 
		mov ESP, EBP
		pop EBP
		ret
afisare_sir_fisier ENDP

suma_elemente_sir PROC ;conventia cdecl
	push EBP
	mov EBP, ESP			;pregatim stack frame-ul
	
	mov ECX, [EBP + 8]		;in ECX avem numarul de elemente din sir 
	mov EDI, [EBP + 12]		;in EDI avem adresa sirului
	
	mov EDX, 0				;cu registrul EDX ne deplasam prin sir 
	mov EAX, 0				;in EAX calculam suma elementelor din  sir
	calcul_suma: 
		add EAX, [EDI][EDX]	;adaugam un nou element la suma
		add EDX, 4			;trecem la urmatorul element din sir
	loop calcul_suma		
	
	final: 
		mov ESP, EBP
		pop EBP
		ret
suma_elemente_sir ENDP


calcul_medie_histograma MACRO lgsir, sir, media, suma_medie
		push ECX
		push EDI
		push EDX
		
		push offset sir						;apelam functia de calculare a sumei elementelor din sir conform cdecl 
		push lgsir	
		call suma_elemente_sir
		add ESP, 8
		
		mov suma_medie, EAX					;in suma_medie avem suma elementelor din sir			
		
		FINIT 								;initializam coprocesorul matematic 
		fild suma_medie						;incarcam pe stiva coprocesorului suma frecventelor de aparitie
		fild lgsir							;incarcam pe stiva coprocesorului numarul de elemente din histograma
		fdiv								;calculam media						
		fstp media							;retinem rezultatul in variabila media
		
		pop EDX
		pop EDI
		pop ECX
ENDM

calcul_deviatie MACRO sir, lgsir, media, x, suma
LOCAL calcul
	push ECX								;salvam registrii care urmeaza a fi folositi in macro pe stiva 
	push ESI
	push EDX
	
	mov ECX, lgsir							;in ECX punem lungimea sirului
	mov ESI, 0								;cu ESI ne deplasam prin sir
	calcul:
		mov EDX, sir[ESI]
		mov x, EDX
		FINIT
		fild x								;incarcam pe stiva elementul curent din sir la care ne aflam
		fld media							;incarcam pe stiva valoarea mediei
		fsub 								;facem scaderea dintre cele doua
		fabs								;aflam valoarea absoluta
		fld ST(0)							
		fmul 								;aflam patratul diferentei 
		fld suma							;adunam noua diferenta la suma 
		fadd 
		fstp suma
		
		add ESI, 4							;trecem la urmatorul element
	loop calcul
	
	mov EDX, lgsir
	sub EDX, 1
	mov x, EDX								;in variabila x vom avea lgsir - 1
	
	FINIT
	fld suma
	fild x
	fdiv 									;facem raportul dintre suma calculata anterior si n - 1 (n este lgsir)
	fsqrt									;aflam radicalul raportului
	fstp deviatie 							;pastram rezultatul in variabila deviatie
	
	pop EDX									;recuperam valoarea registriilor de pe stiva 
	pop ESI
	pop ECX
ENDM 

eliminare_valori MACRO sir, lgsir, val_inf, val_sup, deviatie
LOCAL eliminare, v2, fin, afisare
	push EDI
	push ECX
	push EDX
	push ESI
	
	push offset mod_scriere				;deschidem fisierul eliminare.txt
	push offset fisier_eliminare
	call fopen
	add ESP, 8
	
	mov ESI, EAX						;in ESI avem pointer catre fisierul in care se va face scrierea 
	
	
	FINIT 								;initializam stiva coprocesorului
	fld deviatie						;incarcam pe stiva coprocesorului valoarea deviatiei
	fild doi							;incarcam pe stiva coprocesorului valoarea 2
	fmul								;realizam produsul 2 * deviatie
	fstp val_sup						;pastram in variabila val_sup rezultatul
	fld deviatie						;incarcam pe stiva coprocesorului valoarea deviatiei
	fild minus_2						;incarcam pe stiva coprocesorului valoarea -2
	fmul								;realizam produsul (-2) * deviatie
	fstp val_inf	
	
	
	mov EDI, 0							;cu EDI ne deplasam prin sir 
	mov ECX, lgsir						
	
	eliminare: 
		mov EDX, sir[EDI]
		mov x, EDX
		
		FINIT
		fild x
		fcomp val_sup
		fnstsw AX						;copiem valoarea flag-urilor c0, c2, c3 in AX
		sahf							;incarcam rezulatul in EFLAGS pt a ne putea folosi de jump-uri
	
		jbe v2
		jmp fin
	
		v2:
			FINIT
			fild x
			fcomp val_inf
			fnstsw AX					;copiem valoarea flag-urilor c0, c2, c3 in AX
			sahf						;incarcam rezulatul in EFLAGS pt a ne putea folosi de jump-uri
			
			jae afisare
			jmp fin
			
		afisare:						;ajungem aici daca elementul e mai mic decat val_sup si mai mare decat val_inf
			push ECX
			push EDI
			
			push x
			push offset format_intreg
			push ESI
			call fprintf
			add ESP, 12
			
			pop EDI
			pop ECX
			
	fin:
		add EDI, 4						;trecem la urmatorul element din sir
	loop eliminare
	
	push ESI							;inchidem fisierul eliminare.txt
	call fclose
	add ESP, 4
	
	pop ESI
	pop EDX
	pop ECX
	pop EDI
ENDM 
	
start:
	push offset mesaj_inceput   		;afisam mesajul de inceput pentru a semnala utilizatorului ca fisierul de intrare a fost incarcat
	call printf
	add ESP, 4
	
	push offset fisier_numere
	call printf
	add ESP, 4
	
	push offset new_line
	call printf
	add ESP, 4
	
deschidere_fisier:						;deschidem fisierul numere.txt
	push offset mod_citire
	push offset fisier_numere
	call fopen
	add ESP, 8
	 
	mov ESI, EAX						;in ESI retinem pointer-ul la fisier	 
	
	mov EDI, 0					  		;cu EDI ne deplasam prin sirul sir
	citire:
		push offset x					;citim pe rand cate un numar din fisier
		push offset format_intreg
		push ESI
		call fscanf
		add ESP, 12
		
		mov EBP, x						;adaugam numerele pe rand in sir 
		mov sir[EDI], EBP
		
		mov EBP, EAX					;in EBP retinem numarul de argumente citite corect de fscanf
		
		add EDI, 4						;trecem  la urmatoarea pozitie din sir 			
			
		mov EDX, 1						
		cmp EDX, EBP					;verificam daca s-a citit corect un numar din sir
	je citire
		
	mov sir[EDI], 0						;s-a citit ultimul numar de doua ori il eliminam din sir
	sub EDI, 4
	
inchidere_fisier:						;inchidem fisierul numere.txt
	push ESI
	call fclose
	add ESP, 4
	
	mov EAX, EDI
	xor EDX, EDX
	mov ECX, 4
	div ECX								;calculam numarul efectiv de elemente din sir
	
	mov lgsir, EAX						;lgsir retine numarul de elemente 


minim:	
	push offset mesaj_minim
	call printf
	add ESP, 4
	
	push ECX				;punem registrii folositi in procedura cautare_minim pe stiva 
	push EDX
	push EDI
	
	push offset sir			;apelam procedura cautare_minim conform conventiei cdecl
	push lgsir
	call cautare_minim
	add ESP, 8
	
	pop EDI					;recuperam valorile initiale ale registriilor de pe stiva 
	pop EDX
	pop ECX
	
	mov min, EAX			;functia returneaza in EAX minimul din sir pe care il vom retine in variabila min 
	
	push min				;afisam minimul				
	push offset format_intreg
	call printf
	add ESP, 8

maxim:	
	push offset mesaj_maxim
	call printf
	add ESP, 4
	
	push ECX				;punem registrii folositi in procedura cautare_maxim pe stiva
	push EDX
	push EDI
	
	push offset sir			;apelam procedura cautare_maxim conform conventiei cdecl
	push lgsir
	call cautare_maxim
	add ESP, 8
	
	pop EDI					;recuperam valorile initiale ale registriilor de pe stiva 
	pop EDX
	pop ECX
	
	mov max, EAX			;functia returneaza in EAX maximul din sir pe care il vom retine in variabila max
	
	push max				;afisam maximul		
	push offset format_intreg
	call printf
	add ESP, 8
	
	push offset new_line
	call printf
	add ESP, 4
	
	push offset mod_scriere		;deschidem fisierul unde pastram minimul si maximul din sir
	push offset fisier_minim_maxim
	call fopen 
	add ESP, 8
	
	mov EDI, EAX			;in EDI se salveaza pointer-ul catre fisierul minmax.txt
	
	push max				;in fisierul minmax.txt pastram minimul si maximul din sir
	push min
	push offset format_intregi
	push EDI
	call fprintf
	add ESP, 16
	
	push EDI				;inchidem fisierul minmax.txt
	call fclose
	add ESP, 4
	
	push offset mesaj_salvat
	call printf
	add ESP, 4
	
	push offset fisier_minim_maxim
	call printf
	add ESP, 4
	
	push offset new_line
	call printf
	add ESP, 4
	
	xor EAX, EAX
	xor ECX, ECX 
	mov ECX, lgsir			;in ECX punem lungimea sirului initial, sir, pentru ca cu ajutorul unui loop sa ii parcurgem toate elementele 
	mov ESI, 0				;cu ESI ne vom deplasa prin sirul sir 
	mov EDI, 0				;cu EDI ne vom deplasa prin sirul sir_numere
	mov EDX, 0				;in EDX vom calcula cate elemente are sir_numere
	
	creare_sir_fara_duplicate:	;vom crea sirul sir_numere care va contine elemetele din sir, dar fara duplicate 
		push ECX				;punem pe stiva toti registrii care urmeaza a fi folositi in procedura cautare_element_sir
		push EDX
		push EDI
		push EBX

		push offset sir_numere		;apelam procedura conform cdecl
		push EDX
		push sir[ESI]
		call cautare_element_sir
		add ESP, 12
		
		pop EBX			;recuperam valorile initiale ale registriilor de pe stiva
		pop EDI
		pop EDX
		pop ECX
		
		mov EBX, 0
		cmp EAX, EBX		
		je adaugare_element	;daca EAX e 0 inseamna ca numarul nu se afla inca in sir_numere ceea ce insemna ca trebuie sa il adaugam
		jmp terminare
		
		adaugare_element:	
			mov EBX, sir[ESI]			;adugam elementul din sir in sir_numere daca nu a aparut inca 	
			mov sir_numere[EDI], EBX
			inc EDX						;incrementam numarul de elemente deoarece tocmai am adaugat un element nou in sir_numere
			add EDI, 4					;trecem la urmatorul element din sir 
			
		terminare:
			add ESI, 4			;trecem la urmatorul element din sir 
	loop creare_sir_fara_duplicate
	
	mov lgsir_numere, EDX		;in lgsir_numere vom retine numarul de elemente al lui sir_numere
	
	mov ESI, 0				;cu ESI ne deplasam prin sirul histograma_numere
	mov ECX, lgsir_numere	
	
	creare_histograma:
		push EBX			;punem registrii pe care ii folosim in procedura numar_aparitii_element_sir pe stiva		
		push ECX
		push EDX
		push EDI
		
		push offset sir 	;apelam procedura conform cdecl
		push lgsir
		push sir_numere[ESI]
		call numar_aparitii_element_sir
		add ESP, 12
		
		pop EDI				;recuperam valorile initiale ale registriilor de pe stiva
		pop EDX
		pop ECX
		pop EBX
		
		mov histograma_numere[ESI], EAX		;punem in elementele din histograma frecventa de aparitiei a fiecarui element din sir_numere aflat pe pozitia curenta
		add ESI, 4							;trecem la urmatorul element atat in sir_numere cat si in histograma_numere
	loop creare_histograma
	
	calcul_medie_histograma lgsir_numere, histograma_numere, media, suma_medie		;cu ajutorul unui macro calculam media
	
	calcul_deviatie sir, lgsir, media, x, suma				;cu ajutorul unui macro calculam deviatia
	
	
	afisare_optiuni:
		push offset mesaj_optiuni			;afisam meniul de optiuni 
		call printf 
		add ESP, 4
		
		push offset optiune1
		call printf 
		add ESP, 4
		
		push offset optiune2
		call printf 
		add ESP, 4
		
		push offset optiune3
		call printf 
		add ESP, 4
		
		push offset optiune4
		call printf 
		add ESP, 4
		
		push offset mesaj_exit
		call printf
		add ESP, 4
		
		push offset mesaj_alegere_optiune
		call printf
		add ESP, 4
	
	alegere_optiune:						;utilizatorul va alege o optiune
		push offset optiune
		push offset format_intreg_citire
		call scanf
		add ESP, 8
		
	comparare_cu_5:
		mov EDX, 5
		cmp optiune, EDX
		je final_program				;daca alege 5 programul se termina
		jg afisare_eroare				;daca optiunea e mai mare ca si 5 se va afisa un mesaj de eroare deoarce nu exista optiuni mai mari
		jmp comparare_cu_1
	
	comparare_cu_1:
		mov EDX, 1
		cmp optiune, EDX
		jl afisare_eroare				;daca optiunea e mai mica ca si 1 se va afisa un mesaj de eroare deoarece nu exista optiuni mai mici 
		je optiune_1					
		jmp comparare_cu_2				;daca optiunea nu e 1 se incearca compararea cu 2
	
	afisare_eroare:
		push offset mesaj_optiune_neexistenta
		call printf
		add ESP, 4
		
	optiune_1:
		push offset mod_scriere				;daca optiunea e 1 se deschide fisierul histograma.txt
		push offset fisier_histograma
		call fopen
		add ESP, 8
		
		mov ESI, EAX						;ESI retine pointer catre fisierul histograma.txt
		
		push ESI							;se pun pe stiva registrii folositi in procedura afisare_sir_fisier
		push EDI
		push ECX
		push EDX
		push EBX
		
		push offset format_intreg			;se apeleaza functia conform cdecl
		push offset sir_numere				;se afiseaza sirul sir_numere care contine elementele fara duplicate 
		push ESI
		push lgsir_numere
		call afisare_sir_fisier
		add ESP, 16
		
		pop EBX 							;recuperam valorile initiale ale registriilor de pe stiva
		pop EDX
		pop ECX
		pop EDI
		pop ESI
		
		push offset new_line
		push ESI
		call fprintf
		add ESP, 4
		
		push ESI							;se pun pe stiva registrii folositi in procedura afisare_sir_fisier
		push EDI
		push ECX
		push EDX
		push EBX
		
		push offset format_intreg			;se apeleaza functia conform cdecl
		push offset histograma_numere		;se afiseaza histograma_numere, adica frecventele de apritie a tuturor numerelor din sir_numere
		push ESI
		push lgsir_numere
		call afisare_sir_fisier
		add ESP, 16
		
		pop EBX 						;recuperam valorile initiale ale registriilor de pe stiva
		pop EDX
		pop ECX
		pop EDI
		pop ESI
		
		push ESI						;inchidem fisierul histograma.txt
		call fclose
		add ESP, 4
		
		push offset mesaj_optiune_1
		call printf
		add ESP, 4
		
		push offset mesaj_salvat
		call printf
		add ESP, 4
		
		push offset fisier_histograma
		call printf
		add ESP, 4
		
		push offset new_line
		call printf
		add ESP, 4
		
		jmp final_loop
	comparare_cu_2:
		mov EDX, 2
		cmp optiune, EDX
		je optiune_2
		jmp comparare_cu_3					;daca optiunea nu e 2 se incerca compararea cu 3
	optiune_2:
		push offset mod_scriere				;deschidem fisierul media.txt
		push offset fisier_medie
		call fopen
		add ESP, 8
		
		mov ESI, EAX						;in ESI retinem pointer catre fisierul media.txt
		
		push dword ptr [media + 4]			;afisam in fisier media 
		push dword ptr [media]
		push offset format_real
		push ESI
		call fprintf
		add ESP, 16
		
		push ESI							;inchidem fisierul media.txt
		call fclose
		add ESP, 4
		
		push offset mesaj_optiune_2
		call printf
		add ESP, 4
		
		push offset mesaj_salvat
		call printf
		add ESP, 4
		
		push offset fisier_medie
		call printf
		add ESP, 4
		
		push offset new_line
		call printf
		add ESP, 4
		
		jmp final_loop
	comparare_cu_3:
		mov EDX, 3
		cmp optiune, EDX
		je optiune_3
		jmp comparare_cu_4					;daca optiunea nu e 3 se incerca compararea cu 4
	optiune_3:
		push offset mod_scriere				;deschidem fisierul deviatie.txt
		push offset fisier_deviatie
		call fopen
		add ESP, 8
		
		mov ESI, EAX						;in ESI retinem pointer catre fisierul deviatie.txt
		
		push dword ptr [deviatie + 4]		;afisam in fisier deviatia
		push dword ptr [deviatie]
		push offset format_real
		push ESI
		call fprintf
		add ESP, 16
		
		push ESI							;inchidem fisierul deviatie.txt
		call fclose
		add ESP, 4
		
		push offset mesaj_optiune_3
		call printf
		add ESP, 4
		
		push offset mesaj_salvat
		call printf
		add ESP, 4
		
		push offset fisier_deviatie
		call printf
		add ESP, 4
		
		push offset new_line
		call printf
		add ESP, 4
		
		jmp final_loop
	comparare_cu_4:
		mov EDX, 4
		cmp optiune, EDX
		je optiune_4
		jmp final_loop						;daca optiunea nu e nici 4 se trece la final 
	optiune_4:
		push offset mesaj_optiune_4
		call printf  
		add ESP, 4
		
		push offset mesaj_salvat
		call printf
		add ESP, 4
		
		push offset fisier_eliminare
		call printf
		add ESP, 4
		
		push offset new_line
		call printf
		add ESP, 4
		
		eliminare_valori sir, lgsir, val_inf, val_sup, deviatie
		
		
	final_loop:
	jmp afisare_optiuni
	
	final_program:
		push 0
		call exit
end start