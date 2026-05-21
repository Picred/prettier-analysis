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


