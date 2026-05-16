workspace "Prettier 3.8.x" "C4 Model for Prettier Project" {
    model {
        developer = person "Developer" "Writes source code and defines styling criteria." "User"
        
        enterprise = group "Prettier Code Formatter" {
            // Context
            prettier = softwareSystem "Prettier (v3.8.x)" "Code formatter tool that parses and rewrites code." "Target" {
                // Container
                coreInfrastructure = container "CLI & API Layer" "Handles command-line interface operations and programmatic API exposure." "Node.js"
                configLayer = container "Configuration Layer" "Resolves and applies configuration rules (e.g., .prettierrc)." "JavaScript / cosmiconfig"
                pluginLayer = container "Plugin System" "Dynamic loading of language parsers and printers." "JavaScript"
                processingEngine = container "Processing Engine" "Core formatting logic (Pure function: string-in, string-out)." "JavaScript" {
                    // Component
                    parserLayer = component "Parser Layer" "Selects and applies the language-specific parser." "JavaScript"
                    astProcessing = component "AST Processing" "AST generation and transformation. Manages comments attached to nodes." "JavaScript"
                    printingLayer = component "Printing Layer" "Traverses the AST and generates the formatted string of code." "JavaScript"
                }
            }
        }

        fs = softwareSystem "File System" "Stores source files and configurations." "External"
        ide = softwareSystem "IDE / Editor" "User interface for coding." "External"
        cicd = softwareSystem "CI/CD Pipeline" "Automation for compliance of styling rules." "External"

        # Context
        developer -> ide "Writes code using" "GUI / Human Interaction" "Solid"
        

        # Container
        ide -> coreInfrastructure "Requests code formatting" "Node.js API / IPC (Async)" "Solid"
        cicd -> coreInfrastructure "Executes formatting tasks" "CLI Standard I/O (Sync)" "Solid"

        coreInfrastructure -> configLayer "Delegates config resolution" "Internal Function Call (Async)" "Solid"
        coreInfrastructure -> pluginLayer "Initializes plugins" "Dynamic Import (Sync/Async)" "Solid"
        
        configLayer -> fs "Reads configuration files" "OS File System API (Async)" "Solid"
        coreInfrastructure -> fs "Reads and overwrites source files" "OS File System API (Async)" "Solid"
        
        coreInfrastructure -> processingEngine "Invokes core formatting logic" "Internal Function Call (Sync)" "Solid"
        pluginLayer -> processingEngine "Injects custom parsers and printers" "In-memory Object Reference (Sync)" "Solid"
        

        # Component
        coreInfrastructure -> parserLayer "Passes source code string" "Internal Function Call (Sync)" "Solid"
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
