workspace "Prettier 3.8.x" "C4 Model for Prettier Project" {
    model {
        developer = person "Developer" "Writes source code and defines styling criteria." "User"
        
        enterprise = group "Prettier Code Formatter" {
            prettier = softwareSystem "Prettier (v3.8.x)" "Code formatter tool that parses and rewrites code." "Target" {
                
                // Entry Points Separati
                apiLayer = container "API Layer" "Programmatic interface (exports isolated functions like format())." "Node.js / JavaScript"
                cliLayer = container "CLI Layer" "Parses command-line arguments, reads files, and invokes API/Core." "Node.js"
                
                // Layers Interni
                configLayer = container "Configuration Layer" "Resolves and applies configuration rules (e.g., .prettierrc)." "JavaScript / cosmiconfig"
                pluginLayer = container "Plugin System" "Dynamic loading of language parsers and printers." "JavaScript"
                
                processingEngine = container "Processing Engine" "Core formatting logic (Pure function: string-in, string-out)." "JavaScript" {
                    parserLayer = component "Parser Layer" "Selects and applies the language-specific parser." "JavaScript"
                    astProcessing = component "AST Processing" "AST generation and transformation. Manages comments attached to nodes." "JavaScript"
                    printingLayer = component "Printing Layer" "Traverses the AST and generates the formatted string of code." "JavaScript"
                }
            }
        }

        // Sistemi Esterni
        fs = softwareSystem "File System" "Stores source files and configurations." "External"
        ide = softwareSystem "IDE / Editor" "User interface for coding." "External"
        cicd = softwareSystem "CI/CD Pipeline" "Automation for compliance of styling rules." "External"

        # Context Relationships
        developer -> ide "Writes code using" "GUI / Human Interaction" "Solid"
        developer -> cliLayer "Runs manual formatting commands" "Terminal I/O" "Solid"

        # Container Relationships
        ide -> apiLayer "Reads / Writes code via API calls" "Node.js API (Async)"
        cicd -> cliLayer "Executes formatting tasks" "CLI Standard I/O (Sync)" "Solid"

        cliLayer -> apiLayer "Invokes formatting functions" "Internal Function Call" "Solid"
        cliLayer -> configLayer "Triggers config resolution" "Internal Function Call" "Solid"
        cliLayer -> fs "Reads/Writes source files" "OS File System API (Async)"

        apiLayer -> configLayer "Resolves configuration" "Internal Function Call" "Solid"
        apiLayer -> pluginLayer "Initializes plugins" "Dynamic Import" "Solid"
        apiLayer -> processingEngine "Delegates string formatting" "Internal Function Call" "Solid"
        
        configLayer -> fs "Reads config files (.prettierrc)" "OS File System API (Async)"

        # Component relationships
        configLayer -> parserLayer "Injects config rules" "In-memory Object Reference" "Solid"
        parserLayer -> pluginLayer "Takes custom parsers/printers" "In-memory Object Reference"
        
        apiLayer -> parserLayer "Passes source code string" "Internal Function Call (Sync)" "Solid"
        
        parserLayer -> astProcessing "Passes raw AST" "In-memory AST Object (Sync)" "Solid"
        astProcessing -> printingLayer "Passes massaged AST" "In-memory AST Object (Sync)" "Solid"
    }

    views {
        systemContext prettier "Context" {
            include *
            include developer
            autoLayout lr
        }
        
        container prettier "Containers" {
            include *
            include developer
            autoLayout lr
        }
        
        component processingEngine "Components" {
            include *
            include apiLayer
            include configLayer
            include pluginLayer
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background darkblue
                color white
            }
            element "Target" {
                background steelblue
                color white
            }
            element "External" {
                background grey
                color white
            }
            element "Container" {
                background #438dd5
                color white
            }
            element "Component" {
                background #85bbf0
                color black
            }
            
            relationship "Solid" {
                dashed false
                thickness 2
                color grey
            }
        }
    }
}
