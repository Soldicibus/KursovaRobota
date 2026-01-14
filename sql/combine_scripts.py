import os
import re

def get_sql_files(directory):
    sql_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".sql"):
                sql_files.append(os.path.join(root, file))
    return sorted(sql_files)

def extract_definitions(content):
    definitions = []
    # Find start of CREATE OR REPLACE ...
    # We need to iterate through the string to handle nested parentheses for arguments
    
    # Regex to find the start of the definition
    start_pattern = re.compile(r"CREATE\s+OR\s+REPLACE\s+(FUNCTION|PROCEDURE)\s+([a-zA-Z0-9_.]+)\s*\(", re.IGNORECASE)
    
    for match in start_pattern.finditer(content):
        type_ = match.group(1).upper()
        name = match.group(2)
        start_index = match.end()
        
        # Now find the matching closing parenthesis
        balance = 1
        current_index = start_index
        args_start = start_index
        
        while current_index < len(content) and balance > 0:
            char = content[current_index]
            if char == '(':
                balance += 1
            elif char == ')':
                balance -= 1
            current_index += 1
            
        if balance == 0:
            # We found the closing parenthesis
            args = content[args_start:current_index-1] # Exclude the last ')'
            
            # Remove single line comments
            args = re.sub(r'--.*', '', args)
            # Remove multi-line comments
            args = re.sub(r'/\*.*?\*/', '', args, flags=re.DOTALL)
            
            # Clean up args: remove newlines and extra spaces
            args = " ".join(args.split())
            definitions.append((type_, name, args))
            
    return definitions

def clean_args_for_drop(args_str):
    # Split arguments by comma, respecting parentheses
    args = []
    current_arg = []
    balance = 0
    
    for char in args_str:
        if char == '(':
            balance += 1
        elif char == ')':
            balance -= 1
            
        if char == ',' and balance == 0:
            args.append("".join(current_arg).strip())
            current_arg = []
        else:
            current_arg.append(char)
            
    if current_arg:
        args.append("".join(current_arg).strip())
        
    # Process each argument to remove DEFAULT ...
    cleaned_args = []
    for arg in args:
        # Remove DEFAULT value. 
        # DEFAULT is usually the last part of the arg definition.
        # We look for " DEFAULT " (case insensitive) and take everything before it.
        # Be careful not to match "DEFAULT" inside a string or something, but for args it's unlikely.
        match = re.search(r'\s+DEFAULT\s+', arg, re.IGNORECASE)
        if match:
            arg = arg[:match.start()]
        cleaned_args.append(arg)
        
    return ", ".join(cleaned_args)

def main():
    directories = ["FUNCTIONS", "PROCEDURES"]
    output_file = "all_procedures_and_functions.sql"
    
    all_content = []
    definitions = []

    for d in directories:
        if not os.path.exists(d):
            continue
        files = get_sql_files(d)
        for f in files:
            with open(f, "r", encoding="utf-8") as file:
                content = file.read()
                all_content.append(f"-- Source: {f}\n")
                all_content.append(content)
                all_content.append("\n\n")
                
                defs = extract_definitions(content)
                definitions.extend(defs)

    with open(output_file, "w", encoding="utf-8") as out:
        out.write("-- Combined Procedures and Functions\n")
        out.write("-- Generated automatically\n\n")
        
        out.write("-- DROP statements\n")
        # Sort definitions to have a deterministic order
        definitions.sort(key=lambda x: (x[0], x[1], x[2]))
        
        for type_, name, args in definitions:
            cleaned_args = clean_args_for_drop(args)
            out.write(f"DROP {type_} IF EXISTS {name}({cleaned_args}) CASCADE;\n")
        
        out.write("\n-- Definitions\n")
        for chunk in all_content:
            out.write(chunk)

if __name__ == "__main__":
    main()
