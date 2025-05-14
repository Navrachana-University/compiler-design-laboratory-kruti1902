Project Title: Compiler for Surati Language

Description:
This project implements a basic compiler for the Surati language using Flex and Bison. It supports lexical analysis, parsing, and generation of intermediate code (three-address code). The compiler reads source files written in Surati syntax and produces debug outputs and intermediate representation.

Author: proff. vaibhavi patel
Name: [Kruti Chauhan]
Roll Number: [22000935]

How to Run:
1. Run Bison to generate parser:
   bison -d parser.y

2. Run Flex to generate lexer:
   flex lexer.l

3. Compile the generated code:
   gcc lex.yy.c parser.tab.c -o compiler

4. Execute:
   ./compiler < input1.txt

Outputs:
- debug.txt: Debugging output
- tac.txt: Three address code

Note:
Make sure you have Flex and Bison installed before running.

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/bPoO8GTw)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=19527921&assignment_repo_type=AssignmentRepo)
