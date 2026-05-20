# Context level
High level view. It shows the relationship between prettier and the external world.
Actors:
- IDE (contains the user's code and calls prettier to format the code);

- Developer (interacts with the code);

- File System configuration resolution (manage the static configuration files saved in the project):
    - `src/config/config-searcher.js`                
    - `src/config/load-config.js`                  
    - `src/config/load-external-config.js`
    

Developer --> IDE (Writes code and saves it)
Developer --> CLI (Writes commands in the terminal)
IDE --> Prettier (Software System) (Sends the file that has to be formatted)
CLI --> Prettier (Software System) (Passes flags extracted from options.js)
Prettier (Software System) --> File System (Reads .prettierrc through load-config.js)


# Container level
3 main containers:

### CLI container (Interface for commands in the terminal)
Files : `src/cli/*`
Manages the node.js environment, parses the lines in the terminal, manages the output and with the help of File System finds code to format.

After the files and flags are analyzed by the *CLI container*, the raw text is passed to the *Core Engine Container*

### Core Engine Container
Files: `src/main/core.js`, `src/index.js`

Receives a string and coordinates the formatting process and returns the formatted string. It also manages the patterns seen previously (Visitor, Builder).

(Prettier APIs = Core Engine interface, they are not a container because they are not an autonomous and executable unit, because they do not run in a separated process)

### Language Plugin Container
Files: `src/language-*/`

Each programming language that has to be formatted has its own separated module. Each folder contains third part parsers and the rules that are used to print the AST of that specific language.


### Container's Use Cases
- Formatting via CLI (terminal)
    - *Trigger*: Developer runs a command .
    - *CLI Initialization*: CLI Container (src/cli/) boots up and parses terminal flags.
    - *File Scanning*: CLI Container reads the raw text from the specified files on disk.
    - *Core Delegation*: CLI passes the text and options to the Core Engine Container (src/main/core.js).
    - *Plugin Processing*: Core Engine detects the file extension and calls the matching Language Plugin (e.g., src/language-js/) to parse and generate the layout.
    - *Output*: Core Engine returns the formatted string to the CLI Container, which overwrites the file on disk.


- Formatting via IDE
    - *Trigger*: Developer saves a file or triggers formatting inside the IDE.
    - *CLI Bypass*: The IDE Extension bypasses the CLI and calls the Core Engine Container directly via API.
    - *Config Resolution*: Core Engine scans the project folder to load static configs (like .prettierrc).
    - *Plugin Processing*: Core Engine sends the text to the corresponding Language Plugin based on the editor's file type.
    - *Output*: Core Engine returns the formatted string directly to the IDE, which updates the live editor screen without direct disk writes.

### Similarities with clean architecture blueprint
Prettier's structure follows the Clean Architecture principles, in fact its aim is the same: to protect the core of the application from external details.

Clean architecture's circles (from the inner one to the outer one): 
- Core rules (Entities): it is the engine independent from the language made of the printer (`src/document/printer/printer.js`) and the builders (`group.js` and `indent.js`). It does not know which language is being formatted, it only calculates margins, rows and spaces.
- Application Business Rules (Use Cases): process coordination. The file `src/main/core.js` receives the text and chooses which plugin has to be called, takes the layout commands and passes them to the printer.
- Interface adapters (Gateways/Controllers): the language plugins (`src/language-*/`) and the configuration module (`/src/config/`) act as translators, transforming an external AST and making it comprehensible for Prettier's core.
- Frameworks & Drivers (Details): CLI, external IDEs and third part parsers.

Due to the fact that the program follows clean architecture principles, the dependency rule is respected, so they all point towards the inner part. Moreover the inner circles are less likely to be modified, so that it is more difficult to break the program after modifying something

# Component level
Let's analyze the components of the main container previously analyzed: the *Core Engine Container*.

Inside the Core Engine Container 4 main elements can be found:
- *Configuration Resolver*: the key file is `src/config/resolve-config.js`. It is the core's starting point, in fact it communicates with the external File System to gather and unify style rules.
- *AST parser and traverser*: the key files are `src/language-js/print/estree.js` and `src/main/core.js`. This component takes the raw code and calls the parser to transform it in an AST. Afterwards it analyzes its structure.
- *Layout instruction builder*: the key file is `src/document/builders/group.js`. While the AST is being analyzed, this component builds the intermediate representation (the nodes are translated in layout commands).
- *Line-Wrapping Printer*: the key file is `src/document/printer/printer.js`. It receives the intermediate representation and simulates the command execution, calculates the maximum row length and then returns the formatted line.

### SOLID violation

#### Single responsibility principle (SRP)
A class or an object should have only one reason to change

Violated: *Yes*

The file `src/document/printer/printer.js` tends to be a 'God object', so a module with too many responsibilities because it manages the status of the current row, the backtracking algorithm (if a row has too many characters) and the internal cache, to avoid to analyze the same nodes more than one time.

#### Open/Closed principle (OCP)
    
Software entities should be open to extension, but closed to changes

Violation: *Yes*

The files that manage the AST analysis (for example `src/language-js/print/estree.js`) have a lot of conditional constructs. Therefore, each time a new functionality has to be added, it is not enough to add a new isolated file, but the conditional construct, for example a "switch-case", has to be modified, adding a new 'case'. As a consequence the module is open to changes.


#### Explanation
The SOLID violations in Prettier are not errors, but architectural trade-offs: in a software that deals with code formatting it is more important to enhance the efficiency and to prevent memory overload, avoiding the usage of heavy objects, than to follow completely the SOLID principles.

# Architectural characteristics
- Extensibility: it is one of the best characteristics of prettier because it is really easy to add new functionalities. It is supported with the strong separation of the language container.

- Maintainability: having the formatting algorithm isolated in the Entities cirle of the clean architecture, it is easy to adapt to changes without having to modify the central engine.

- Stability: due to the clean architecture division, the program is really stable.

- Efficiency: one of the best characteristics of Prettier. The program must be really fast, because it has to be executed at every save. It is supported with the architectural trade-off on SOLID principles.

- Portability: due to the fact that the *CLI Container* and the *Core Engine* are completely decoupled, the program can be integrated everywhere

- Testability: the inner pipeline is almost unidirectional, so it is not needed to simulate a database or complex networks.

- Usability: the decoupling between *CLI container* and *Core engine* allows external tools to integrate Prettier as an API.

### Coupling and cohesion
Prettier balances its speed and scalability by carefully managing how its internal components interact.

The system relies on high functional cohesion within its core formatting logic: modifying one layout rule will not accidentally damage another.

Connectivity across the system is maintained through loose data coupling. The core engine and the individual language modules never share a global state; they communicate strictly by passing clean data structures, as a consequence the tool can scale its language ecosystem safely.

However, Prettier does not follow these principles in two areas to maximize performance. First, there is a tight control coupling between the user configurations and the printing logic. Second, the system tolerates lower cohesion within the final printing engine: to eliminate memory overhead and maintain high speeds, this single tracks the live line width, executes the backtracking layout algorithm, and manages an aggressive performance cache.

# Conclusion
Prettier's architecture demonstrates a balance between theoretical design and practical efficiency: by mapping its structure to the Clean Archietcture blueprint, Prettier manages to divide the stable and unstable parts of the code.

Moreover, through localized SOLID violations and tight control coupling, the code manages to maximize its execution speed and achieves exceptional scalability and usability. The loose data coupling across different programming languages allows Prettier to grow seamlessly. Eventually, its architectural design perfectly fulfills its core mission: delivering a really fast formatting experience with zero configuration that integrates universally into any development workflow.

