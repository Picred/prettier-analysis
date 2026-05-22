tool `structurizer`

Chiedere riguardo i loop : ex. se per il printing va bene o se non ci devono essere loop in generale.

Chiedere se è meglio tenere una parte che zoomma solo nella parte del component o se ci deve essere una visione di insieme con input e output del livello precedente

Servono le linee di ritorno?


# Context part
- developer (person)
- IDE (external system)
- Prettier (system)
- File system (external system)
- CI/CD Pipeline (external system)

# Container part
- developer (person)
- IDE (external system)
- File system (external system)
- CI/CD Pipeline (external system)
- Prettier container:
    - cli and API layern (?)
    - configuration layer (?)
    - language plugin system
    - core engine

*Spiegare che il cli si può bypassare attraverso le API*

chiedere se cli e API vanno insieme

chiedere se il configuration layer va messo dentro o fuori il processing engine

# Component part
- developer (person)
- IDE (external system)
- File system (external system)
- CI/CD Pipeline (external system)
- Prettier container:
    - cli and API layern (?)
    - configuration layer (?)
    - language plugin system
    - core engine container:
        - parser layer
        - ast processing
        - printing layer

dubbi sulle connessioni a component level dei language plugin.

Chiedere se la creazione della rappresentazione intermedia (Doc) deve avere un componente unico all'interno del component diagram o se invece non serve.

Serve un boundary (rettangolo) attorno al formatting engine nella container part?



# Risposte

File System anche dentro Prettier (DB locale) --> meglio
Se è un DB locale va dentro
--> *NO*
Il File System appartiene al Sistema Operativo dell'utente. Prettier non lo possiede, non lo controlla e non lo ha creato: si limita a chiedere al sistema operativo il permesso di leggere e scrivere file che appartengono all'utente
Il File System è solo il supporto fisico di persistenza dei file dell'utente, ovvero l'ambiente esterno in cui Prettier opera.


Consultare checklist per notazione

*Lavorare su descrizione dall'IDE per ritorno*

*Giusto non fare cicli*

*Specificare perché non analizziamo le componenti di altre cose oltre al core engine* 




1. Linea Piena (Flusso Principale / Sincrono)
Rappresenta una relazione forte, diretta e immediata. Si usa quando un componente chiama direttamente un altro e si ferma in attesa di una risposta per poter continuare il suo lavoro.

Si usa per:

Chiamate dirette a funzioni (Sincrone): Quando il Componente A esegue il Componente B in memoria RAM (es. FunzioneA() che chiama FunzioneB()).

Operazioni di Input/Output (I/O) bloccanti: Un programma che legge o scrive un file sul disco fisso, o che interroga un database locale.

Interazioni dell'utente: L'azione fisica di una persona che clicca su un bottone o digita un comando.

2. Linea Tratteggiata (Flusso Secondario / Asincrono / Disaccoppiato)
Rappresenta una relazione debole, indiretta o di contorno. Si usa quando il legame tra i due blocchi non è rigido, oppure quando lo scambio di dati non avviene in tempo reale.

Si usa per:

Iniezione di dipendenze (Dependency Injection) o Plugin: Quando un componente usa un altro modulo esterno che viene caricato dinamicamente (a runtime) solo se serve, senza che ci sia un legame fisso nel codice.

Comunicazioni Asincrone: Messaggi inviati tramite code (Message Queues), notifiche push, o eventi in cui il Componente A "spara" il dato e continua a fare altro senza aspettare il Componente B.

Passaggio di configurazioni/metadati: Quando una linea non rappresenta un comando, ma semplicemente lo spostamento di informazioni di sottofondo (es. il passaggio di un file di opzioni che serve a istruire il comportamento di un motore).








