workspace "Prettier 3.8.x" "C4 Model for Prettier Project" {
    model {
        developer = person "Developer" "Writes source code and defines styling criteria." "User"
        
        enterprise = group "Prettier Code Formatter" {
            prettier = softwareSystem "Prettier (v3.8.x)" "Code formatter tool that parses and rewrites code." "Target" {
                coreInfrastructure = container "Core Infrastructure" "Handles API and CLI." "Node.js"
                configLayer = container "Configuration Layer" "Resolves .prettierrc." "JS"
                processingEngine = container "Processing Engine" "Logic core." "JS" {
                    parserLayer = component "Parser Layer" "Selects/Executes parsers." "JS"
                    astProcessing = component "AST Processing" "Manages AST and comments." "JS"
                    printingLayer = component "Printing Layer" "Generates final string." "JS"
                }
            }
        }

        fs = softwareSystem "File System" "Stores source and config files." "External"
        ide = softwareSystem "IDE / Editor" "User interface for coding." "External"
        cicd = softwareSystem "CI/CD Pipeline" "Automation for compliance of styling rules" "External"

        developer -> ide "Writes code using" "" "Solid"
        ide -> coreInfrastructure "Sends code" "API" "Solid"
        cicd -> coreInfrastructure "Runs checks via CLI" "" "Solid"
        coreInfrastructure -> configLayer "Requests options" "" "Solid"
        configLayer -> fs "Reads config files" "" "Solid"
        coreInfrastructure -> processingEngine "Sends code for processing" "" "Solid"
        processingEngine -> fs "Reads/Writes source" "" "Solid"
        
        # Level 3 links (Coerenza)
        coreInfrastructure -> parserLayer "Flows source code" "" "Solid"
        parserLayer -> astProcessing "Flows raw AST" "" "Solid"
        astProcessing -> printingLayer "Flows massaged AST" "" "Solid"
        printingLayer -> coreInfrastructure "Returns formatted string" "" "Solid"
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