# Payroll
Implements external subprograms for advanced payroll processing. This code demonstrates linkage and parameter passing within a mainframe environment.

## Overview
This repository contains the assembly code for the PAYROLL program. The program is designed to manage payroll processing through a series of external subprograms, showcasing advanced linkage and parameter passing techniques in a mainframe environment.

## Description
Integrating additional functionality through external subprograms. Each subprogram is responsible for different aspects of payroll processing, from initializing data to calculating payments and deductions.

## Key Features
- **Initialization and Setup**: Sets up the program, defining necessary parameters and storage.
- **Data Processing**: Handles input and processes employee payroll data through a series of calculated subprograms.
- **Reporting**: Generates payroll reports detailing each employee's payment and deductions.

## Subprograms Included
- **BUILDTBL**: Initializes data storage, reading, and packing input data.
- **PROCTBL**: Processes payroll data and calls other subprograms for detailed calculations.
- **CALCNPAY**: Calculates the net pay for each employee.
- **CALCAVG**: Computes average values for reporting.

## Usage
To run this program, you will need access to a system capable of processing IBM assembly language, such as an IBM mainframe or an emulator that supports the ASSIST assembly language.
