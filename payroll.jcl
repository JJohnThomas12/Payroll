*****************************************************************
*                                                               *
*  FUNCTION: To compute payroll for a company using an input    *
*  file containing employee information in packed decimals,and  *
*  leveraging four external subprograms.                        *
*                                                               *
*****************************************************************
*
PAYROLL2  CSECT
*
*  Sets standard entry linkage with R12 as base register
*
         STM   14,12,12(13)  // Saves registers in the caller's save
         LR    12,15         // Copies CSECT address into R12
         USING PAYROLL2,12   // Establishes R12 as the base register
         LA    14,REGSAVE    // R14 points to this CSECT's save
         ST    14,8(,13)     // Stores address of this CSECT's save
         ST    13,4(,14)     // Stores address of caller's save
         LR    13,14         // Points R13 at this CSECT's save
*
*
         LA    11,4095(,12)       // Establishes upper limit
         LA    11,1(,11)          // Adjusts to next addressable area
         USING PAYROLL2+4096,11   // Resets base register for next area
*
*
         LA    1,BTPARMS          // Points R1 to BTPARMS
         L     15,=V(BUILDTBL)    // Sets up call to BUILDTBL
         BALR  14,15              // Calls BUILDTBL subroutine
*
         LA    1,PTPARMS          // Points R1 to PTPARMS
         L     15,=V(PROCTBL)     // Sets up call to PROCTBL
         BALR  14,15              // Calls PROCTBL subroutine
*
*  Standard exit linkage with return code of 0
*
         SR    15,15        // Sets R15 to return code of 0
         L     13,4(,13)    // Points R13 to caller's save area
         L     14,12(,13)   // Restores register 14
         LM    0,12,20(13)  // Restores R0 through R12
*
         BR    14           // Returns to caller
*
         LTORG
*
         ORG   PAYROLL2+((*-PAYROLL2+31)/32)*32
         DC    C'HERE IS THE STORAGE: PAYROLL2 ***'
*
REGSAVE  DS    18F         // Defines the program's register save area
*
BTPARMS  DC    A(PFWHPCT)  // Packs federal withholding percentage
         DC    A(PSWHPCT)  // Packs state withholding percentage
         DC    A(EMPTBL)   // Points to all employee table entries
         DC    A(PEMPCTR)  // Packs employee counter (max 999)
*
PTPARMS  DC    A(PFWHPCT)  // Packs federal withholding percentage
         DC    A(PSWHPCT)  // Packs state withholding percentage
         DC    A(EMPTBL)   // Points to all employee table entries
         DC    A(PEMPCTR)  // Packs employee counter (max 999)
*
* Defines packed decimal variables.
*
EMPTBL   DS    120CL42     // Defines all employee table entries
PFWHPCT  DC    PL4'0'      // Packs federal withholding percentage
PSWHPCT  DC    PL4'0'      // Packs state withholding percentage
PEMPCTR  DC    PL3'0'      // Packs employee counter (max 999)
*
***************************************************************
*                                                             *
*  SUBPROGRAM NAME: BUILDTBL                                  *
*                                                             *
*  Description: Reads an input file, stores values            *
*  in PFWHPCT, PSWHPCT, and then into EMPTBL                  *
*                                                             *
*  Parameters: PFWHPCT -> Federal withholding percentage      *
*              PSWHPCT -> State withholding percentage        *
*              EMPTBL  -> All employee table entries          *
*              PEMPCTR -> Employee count                      *
*                                                             *
***************************************************************
*
$EMPENT1 DSECT             // Defines employee table entry DSECT
$EMPID1  DS    PL5         // Defines employee ID number
$EMPNME1 DS    CL25        // Defines employee name
$HRPAY1  DS    PL3         // Defines hourly pay rate
$HOURS1  DS    PL3         // Defines hours worked
$DEDUCT1 DS    PL3         // Defines deductions
$BONUS1  DS    PL3         // Defines bonus earned
*
$RECORD1 DSECT             // Defines DSECT for input record
$IEMPID1 DS    ZL8         // Defines input field for employee ID
$IHRPAY1 DS    ZL5         // Defines input field for pay rate
$IHOURS1 DS    ZL5         // Defines input field for hours
$IDEDUC1 DS    ZL5         // Defines input field for deduction
$IBONUS1 DS    ZL5         // Defines input field for bonus
$IEMPNME DS    CL25        // Defines input field for employee name
*
BUILDTBL CSECT
*
*  Sets standard entry linkage with R12 as base register.
*
         STM   14,12,12(13)  // Saves registers in caller's save area
         LR    12,15         // Copies CSECT address into R12
         USING BUILDTBL,12   // Establishes R12 as the base register
         LA    14,BTSAVE     // Points R14 to this CSECT's save area
         ST    14,8(,13)     // Stores address of this CSECT's save
         ST    13,4(,14)     // Stores address of caller's save area
         LR    13,14         // Points R13 at this CSECT's save area
*
*
         LM    2,5,0(1)   R2 -> PFWHPCT(4)
*                         R3 -> PSWHPCT(4)
*                         R4 -> EMPTBL(42)
*                         R5 -> PEMCTR(3)
*
         USING $EMPENT1,4           // Establishes addressability
         LA    6,RECORD             // Loads record input buffer to R6
         USING $RECORD1,6           // Establishes addressability
*
         XREAD WHPCT1,80            // Reads first line
         PACK  0(4,2),IFWHPCT1(6)   // Reads federal percentage
         PACK  0(4,3),ISWHPCT1(6)   // Reads state percentage
*
         XREAD RECORD,80
*
LOOP1    BNZ   ENDLOOP1     // Branches to ENDLOOP1 if EOF
*
         AP    0(3,5),=PL1'1'   // Adds 1 to employee counter
*
         PACK  $EMPID1(5),$IEMPID1(8)    // Reads employee ID
         PACK  $HRPAY1(3),$IHRPAY1(5)    // Reads pay rate
         PACK  $HOURS1(3),$IHOURS1(5)    // Reads hours
         PACK  $DEDUCT1(3),$IDEDUC1(5)   // Reads deduction
         PACK  $BONUS1(3),$IBONUS1(5)    // Reads bonus
         MVC   $EMPNME1(25),$RECORD1+28  // Reads employee name
*
         LA    4,42(,4)       // Points R4 to next entry in table
*
         XREAD RECORD,80      // Reads next record
*
         B     LOOP1          // Branches to top of LOOP1 to check EOF
*
ENDLOOP1 DS    0H             // End of data collection
*
         DROP  4,6
*
*  Standard exit linkage with return code of 0.
*
         SR    15,15        // Sets R15 to return code of 0
         L     13,4(,13)    // Points R13 to caller's save area
         L     14,12(,13)   // Restores register 14
         LM    0,12,20(13)  // Restores R0 through R12
*
         BR    14           // Returns to caller
*
         LTORG
*
BTSAVE  DS    18F          // Defines the program's register save area
*
WHPCT1   DS    0H          // Buffer for the first line
IFWHPCT1 DS    ZL6         // Input field for federal percent
ISWHPCT1 DS    ZL6         // Input field for state percent
         DS    CL68        // Unused bytes
*
RECORD   DS    CL80        // Buffer for employee info
*
***************************************************************
*                                                             *
*  SUBPROGRAM NAME: PROCTBL                                   *
*                                                             *
*  Description: Processes the info, creates the output        *
*  by calling CALCNPAY and CALCAVG external subprograms       *
*                                                             *
*  Parameters: PFWHPCT -> Federal withholding percentage      *
*              PSWHPCT -> State withholding percentage        *
*              EMPTBL  -> All employee table entries          *
*              PEMPCTR -> Employee count                      *
*                                                             *
***************************************************************
*
$EMPENT2 DSECT             // Defines employee table entry DSECT
$EMPID2  DS    PL5         // Defines employee ID number
$EMPNME2 DS    CL25        // Defines employee name
$HRPAY2  DS    PL3         // Defines hourly pay rate
$HOURS2  DS    PL3         // Defines hours worked
$DEDUCT2 DS    PL3         // Defines deductions
$BONUS2  DS    PL3         // Defines bonus earned
*
PROCTBL  CSECT
*
*  Sets standard entry linkage with R12 as base register
*
         STM   14,12,12(13)   // Saves registers in caller's save area
         LR    12,15          // Copies CSECT address into R12
         USING PROCTBL,12     // Establishes R12 as the base register
         LA    14,PTSAVE      // Points R14 to this CSECT's save area
         ST    14,8(,13)      // Stores address of this CSECT's save
         ST    13,4(,14)      // Stores address of caller's save area
         LR    13,14          // Points R13 at this CSECT's save area
*
*
         LM    2,5,0(1)   R2 -> PFWHPCT(4)
*                         R3 -> PSWHPCT(4)
*                         R4 -> EMPTBL(42)
*                         R5 -> PEMPCTR(3)
*
         ST    2,CNPPARMS+8       // Points R2 to CNPPARMS storage
         ST    3,CNPPARMS+16      // Points R3 to CNPPARMS storage
         USING $EMPENT2,4         // Establishes addressability
*
         ZAP   DBLWORD(8),0(3,5)  // Puts PEMPCTR in double word
         CVB   6,DBLWORD          // Converts PEMPCTR to binary in R6
*
         LA    7,99               // Loads large number in R7
*
LOOP2    MVI   DETAIL+1,C' '          // Ensures carriage control
         MVC   DETAIL+2(131),DETAIL+1 // Sets DETAIL to all spaces
*
         MVC   OEMPID(9),=X'21202020202020202020' // Ensures correct
         ED    OEMPID(9),$EMPID2       // Prints employee ID.
         MVC   OEMPID(3),OEMPID+1      // Moves employee ID characters
         MVI   OEMPID+3,C'-'           // Ensures the hyphen is added
*
         LA    1,OHRPAY+1              // Loads location of first char
         MVC   OHRPAY(6),=X'2120204B2020' // Ensures correct format
         EDMK  OHRPAY(6),$HRPAY2       // Prints pay rate
         BCTR  1,0                     // Decrements register 1 by 1
         MVI   0(1),C'$'               // Places the dollar sign
*
         MVC   OHOURS(7),=X'402021204B2020' // Ensures correct format
         ED    OHOURS(7),$HOURS2            // Prints hours
*
         MVC   OEMPNME(25),$EMPNME2    // Prints employee name
*
         ZAP   PEMPGPAY(6),$HRPAY2(3)  // Copies to larger field
         MP    PEMPGPAY(6),$HOURS2(3)  // Multiplies HRPAY by hours
         SRP   PEMPGPAY(6),64-2,5     // Shifts to the right two spots
         SP    PEMPGPAY(6),$DEDUCT2(3) // Subtracts GPAY by deduction
         AP    PEMPGPAY(6),$BONUS2(3)  // Adds bonus to GPAY
         AP    PTGRPAY(7),PEMPGPAY(6)  // Adds current GPAY to total
*
         LA    1,OEMPGPAY+1            // Load location of the first
         MVC   OEMPGPAY(11),=X'402020206B2021204B2020'  // Establish
         SRP   PEMPGPAY(6),3,0         // Shift gross pay for output
         EDMK  OEMPGPAY(11),PEMPGPAY   // Display formatted gross pay
         BCTR  1,0                     // Decrement register to move
         MVI   0(1),C'$'               // Insert dollar sign
*
         LA    1,CNPPARMS              // Load address of CNPPARMS
         L     15,=V(CALCNPAY)         // Prepare to call CALCNPAY
         BALR  14,15                   // Execute CALCNPAY subroutine
*
         LA    1,OFEDWITH+1            // Load starting position
         MVC   OFEDWITH(9),=X'40206B2021204B2020'  // Format
         EDMK  OFEDWITH(9),PFEDWITH    // Print federal withholding
         BCTR  1,0                     // Adjust register
         MVI   0(1),C'$'               // Insert dollar sign
*
         LA    1,OSTWITH+1             // Load starting position
         MVC   OSTWITH(9),=X'40206B2021204B2020'  // Format for state
         EDMK  OSTWITH(9),PSTWITH      // Print state withholding
         BCTR  1,0                     // Adjust register
         MVI   0(1),C'$'               // Insert dollar sign
*
         LA    1,OEMPNPAY+1            // Load starting position
         MVC   OEMPNPAY(11),=X'402020206B2021204B2020'  // Format net
         EDMK  OEMPNPAY(11),PEMPNPAY   // Print net pay
         BCTR  1,0                     // Adjust register
         MVI   0(1),C'$'               // Insert dollar sign
*
         SRP   PEMPGPAY(6),5,0         // Shift right to normalize
         AP    PTGRPAY(7),PEMPGPAY(6)  // Add current gross pay
         SRP   PFEDWITH(6),64-3,5      // Normalize federal withholding
         AP    PTFWITH(7),PFEDWITH(6)  // Add current federal
         SRP   PSTWITH(6),64-3,5       // Normalize state withholding
         AP    PTSWITH(7),PSTWITH(6)   // Add current state withholding
         AP    PTNETPAY(7),PEMPNPAY(6) // Add current net pay to total
*
         C     7,=F'17'                // Compare current employee
         BL    NOHDRS                  // Skip header printing if 17
         AP    PPAGECTR(2),=PL1'1'     // Increment page counter
         MVC   OPAGECTR(3),=X'202020'  // Format the page counter
         ED    OPAGECTR(3),PPAGECTR    // Print the page counter
*
         XPRNT SUBHDR,133             // Print first header line
         XPRNT SUBHDR2,133            // Print second header line
         XPRNT COLHDR,133             // Print first column header
         XPRNT COLHDR2,133            // Print second column header
         XPRNT HYPHEN,133             // Print hyphen line
*
         SR    7,7                    // Reset the employee count
*
NOHDRS   DS    0H                     // Label for skipping header
*
         XPRNT DETAIL,133             // Print detailed employee
*
         LA    7,1(7)                 // Increment employee count
*
         LA    4,42(,4)               // Point R4 to the next entry
*
         BCT   6,LOOP2                // Branch to LOOP2
*
         DROP 4                       // Drop addressability
*
         ZAP   TEMPCTR(3),0(3,5)      // Copy employee count to TEMPCTR
         MVC   OEMPCTR(3),=X'202120'  // Format employee count display
         SRP   TEMPCTR(3),2,0         // Shift for proper display
         ED    OEMPCTR(3),TEMPCTR     // Print formatted employee count
         ST    5,CAPARMS+4            // Store pointer to CAPARMS
*
         LA    1,OTGRPAY+1            // Load location of the first
         MVC   OTGRPAY(10),=X'2020206B2021204B2020'  // Establish
         SRP   PTGRPAY(7),5,0         // Shift left by five to format
         EDMK  OTGRPAY(10),PTGRPAY    // Display total gross pay
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Insert dollar sign
*
         LA    1,OTFWITH+1            // Load location of the first
         MVC   OTFWITH(10),=X'4020206B2021204B2020'  // Establish
         SRP   PTFWITH(7),4,0         // Shift left by four
         EDMK  OTFWITH(10),PTFWITH    // Display total federal
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Insert dollar sign
*
         LA    1,OTSWITH+1            // Load location of the first
         MVC   OTSWITH(10),=X'4020206B2021204B2020'  // Establish
         SRP   PTSWITH(7),4,0         // Shift left by four digits
         EDMK  OTSWITH(10),PTSWITH    // Display total state
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Insert dollar sign
*
         LA    1,OTNETPAY+1           // Load location of the first
         MVC   OTNETPAY(10),=X'2020206B2021204B2020'  // Establish
         SRP   PTNETPAY(7),2,0        // Shift left by two to prepare
         EDMK  OTNETPAY(10),PTNETPAY  // Display total net pay
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Place the dollar sign
*
         ZAP   PTOTAL(7),PTGRPAY(7)   // Copy total gross pay to PTOTAL
*
         LA    1,CAPARMS              // Load address of calculation
         L     15,=V(CALCAVG)         // Prepare to call average
         BALR  14,15                  // Call CALCAVG subroutine
*
         LA    1,OAGRPAY+1            // Load location of the first
         MVC   OAGRPAY(10),=X'2020206B2021204B2020'  // Format average
         EDMK  OAGRPAY(10),PAVG       // Display average gross pay
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Insert dollar sign
*
         ZAP   PTOTAL(7),PTFWITH(7)   // Copy total federal
         SRP   0(3,5),64-2,5          // Shift right by two
*
         LA    1,CAPARMS              // R1 points to calculation
         L     15,=V(CALCAVG)         // Call CALCAVG subroutine again
         BALR  14,15                  // Execute average calculation
*
         LA    1,OAFWITH+1            // Load location of the first
         MVC   OAFWITH(10),=X'2020206B2021204B2020'  // Format average
         SRP   PAVG(6),64-1,5         // Shift right by one
         EDMK  OAFWITH(10),PAVG       // Display average federal
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Insert dollar sign
*
         ZAP   PTOTAL(7),PTSWITH(7)   // Copy total state withholding
         SRP   0(3,5),64-2,5          // Shift right by two
*
         LA    1,CAPARMS              // Load address of calculation
         L     15,=V(CALCAVG)         // Prepare to call CALCAVG
         BALR  14,15                  // Call CALCAVG subroutine again
*
         LA    1,OAFWITH+1            // Load location of the first
         MVC   OASWITH(10),=X'2020206B2021204B2020'  // Format average
         SRP   PAVG(6),64-1,5         // Shift right by one
         EDMK  OASWITH(10),PAVG       // Display average state
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Insert dollar sign
*
         ZAP   PTOTAL(7),PTNETPAY(7)  // Copy total net pay
         SRP   0(3,5),64-2,5          // Shift right by two
*
         LA    1,CAPARMS              // Load address of calculation
         L     15,=V(CALCAVG)         // Call CALCAVG subroutine again
         BALR  14,15                  // Execute average calculation
*
         LA    1,OANETPAY+1           // Load location of the first
         MVC   OANETPAY(10),=X'2020206B2021204B2020'  // Format average
         EDMK  OANETPAY(10),PAVG      // Display average net pay
         BCTR  1,0                    // Decrement register by 1
         MVI   0(1),C'$'              // Place the dollar sign
*
         XPRNT SUBHDR,133             // Print first header line
         XPRNT SUBHDR2,133            // Print second header line
         XPRNT TOTAL,133              // Print total header line
         XPRNT EMPTTL,133             // Print employee count
         XPRNT EMPGROSS,133           // Print info on gross pay
         XPRNT EMPFED,133             // Print info on federal
         XPRNT EMPST,133              // Print info on state
         XPRNT EMPNET,133             // Print info on net pay
*
*  STANDARD EXIT LINKAGE WITH RC OF 0
*
         SR    15,15        // Set R15 to 0, return code of 0
         L     13,4(,13)    // Load address of caller's save area
         L     14,12(,13)   // Restore R14 using caller's save area
         LM    0,12,20(13)  // Restore registers R0 through R12
*
         BR    14           // Return control to caller
*
         LTORG              // Define literals
*
PTSAVE   DS    18F          // Define storage for register save area
*
DBLWORD  DC    D'0'         // Define a doubleword initialized to 0
*
CNPPARMS DC A(PEMPGPAY) <- Declared in PROCTBL
         DC A(PEMPNPAY) <- Declared in PROCTBL
         DC A(0)        <- Declared in PAYROLL2 and passed into PROCTBL
         DC A(PFEDWITH) <- Declared in PROCTBL
         DC A(0)        <- Declared in PAYROLL2 and passed into PROCTBL
         DC A(PSTWITH)  <- Declared in PROCTBL
*
CAPARMS  DC A(PTOTAL)   <- Declared in PROCTBL
         DC A(0)        <- Declared in PAYROLL2 and passed into PROCTBL
         DC A(PAVG)     <- Declared in PROCTBL
*
* PACKED DECIMAL VARIABLES
*
PPAGECTR DC    PL2'0'      // Packed page counter, maximum value 999
PEMPID   DC    PL5'0'      // Packed employee ID
PHRPAY   DC    PL3'0'      // Packed hourly pay rate
PHOURS   DC    PL3'0'      // Packed hours worked
PDEDUCT  DC    PL3'0'      // Packed deductions
PBONUS   DC    PL3'0'      // Packed bonus
PEMPGPAY DC    PL6'0'      // Packed calculated employee gross pay
PFEDWITH DC    PL6'0'      // Packed calculated federal withholding
PSTWITH  DC    PL6'0'      // Packed calculated state withholding
PEMPNPAY DC    PL6'0'      // Packed calculated employee net pay
*
PTGRPAY  DC    PL7'0'      // Packed total gross employee pay
PTFWITH  DC    PL7'0'      // Packed total federal withholding
PTSWITH  DC    PL7'0'      // Packed total state withholding
PTNETPAY DC    PL7'0'      // Packed total net employee pay
*
TEMPCTR  DC PL3'0'         // Temporary employee count
PTOTAL   DC PL7'0'         // Storage for calculating average values
PAVG     DC PL6'0'         // Storage for current average value
*
SUBHDR   DC    C'1'        // Carriage control character
         DC    50C' '      // 50 spaces
         DC    CL31'STATE OF ILLINOIS NATIONAL BANK'  // First line
         DC    41C' '      // 41 spaces
         DC    CL7'PAGE:  '  // Start of second line in subheader
OPAGECTR DS    CL3         // Output field for page count
*
SUBHDR2  DC    C' '        // Carriage control character
         DC    48C' '      // 48 spaces
         DC    CL36'SEMI-MONTHLY EMPLOYEE PAYROLL REPORT'  // Line one
         DC    48C' '      // 48 spaces
*
COLHDR   DC    C'0'        // Carriage control character
         DC    CL8'EMPLOYEE'  // Column header one
         DC    3C' '        // 3 spaces
         DC    CL8'EMPLOYEE'  // Column header two
         DC    21C' '       // 21 spaces
         DC    CL6'HOURLY'  // Column header three
         DC    5C' '        // 5 spaces
         DC    CL5'HOURS'   // Column header four
         DC    12C' '       // 12 spaces
         DC    CL8'EMPLOYEE'  // Column header five
         DC    4C' '        // 4 spaces
         DC    CL16'EMPLOYEE FEDERAL'  // Column header six
         DC    4C' '        // 4 spaces
         DC    CL14'EMPLOYEE STATE'  // Column header seven
         DC    10C' '       // 10 spaces
         DC    CL8'EMPLOYEE'  // Column header eight
*
COLHDR2  DC    C' '        // Carriage control character
         DC    CL2'ID'     // Column two header one
         DC    9C' '       // 9 spaces
         DC    CL4'NAME'   // Column two header two
         DC    28C' '      // 28 spaces
         DC    CL3'PAY'    // Column two header three
         DC    4C' '       // 4 spaces
         DC    CL6'WORKED' // Column two header four
         DC    11C' '      // 11 spaces
         DC    CL9'GROSS PAY'  // Column two header five
         DC    9C' '       // 9 spaces
         DC    CL11'WITHHOLDING'  // Column two header six
         DC    7C' '       // 7 spaces
         DC    CL11'WITHHOLDING'  // Column two header seven
         DC    11C' '      // 11 spaces
         DC    CL7'NET PAY'  // Column two header eight
*
HYPHEN   DC    C' '        // Carriage control character
         DC    9C'-'       // 9 hyphens
         DC    2C' '       // 2 spaces
         DC    25C'-'      // 25 hyphens
         DC    3C' '       // 3 spaces
         DC    7C'-'       // 7 hyphens
         DC    3C' '       // 3 spaces
         DC    7C'-'       // 7 hyphens
         DC    5C' '       // 5 spaces
         DC    15C'-'      // 15 hyphens
         DC    4C' '       // 4 spaces
         DC    16C'-'      // 16 hyphens
         DC    4C' '       // 4 spaces
         DC    14C'-'      // 14 hyphens
         DC    3C' '       // 3 spaces
         DC    15C'-'      // 15 hyphens
*
DETAIL   DC    C'0'        // Carriage control character
OEMPID   DS    CL9         // Output field for employee ID
         DC    2C' '       // 2 spaces
OEMPNME  DS    CL25        // Output field for employee name
         DC    4C' '       // 4 spaces
OHRPAY   DS    CL6         // Output field for pay rate
         DC    3C' '       // 3 spaces
OHOURS   DS    CL7         // Output field for hours worked
         DC    9C' '       // 9 spaces
OEMPGPAY DS    CL11        // Output field for gross pay amount
         DC    11C' '      // 11 spaces
OFEDWITH DS    CL9         // Output field for federal withholding
         DC    9C' '       // 9 spaces
OSTWITH  DS    CL9         // Output field for state withholding amount
         DC    7C' '       // 7 spaces
OEMPNPAY DS    CL11        // Output field for net pay
*
TOTAL    DC    C' '        // Carriage control character
         DC    62C' '      // 62 spaces
         DC    CL6'TOTALS' // Line one total header
         DC    65C' '      // 65 spaces
*
EMPTTL   DC    C'0'        // Carriage control
         DC    6C' '       // 6 spaces
         DC    CL20'NUMBER OF EMPLOYEES:'  // Line one employee count
         DC    13C' '      // 13 spaces
OEMPCTR  DS    CL3         // Output field for employee count
         DC    91C' '      // 91 spaces
*
EMPGROSS DC    C'0'        // Carriage control character
         DC    10C' '      // 10 spaces
         DC    CL16'TOTAL GROSS PAY:'  // Line one total gross pay
         DC    9C' '       // 9 spaces
OTGRPAY  DS    CL10        // Output field for total gross pay
         DC    20C' '      // 20 spaces
         DC    CL18'AVERAGE GROSS PAY:'  // Line one average gross pay
         DC    6C' '       // 6 spaces
OAGRPAY  DS    CL10        // Output field for average gross pay
         DC    33C' '      // 33 spaces
*
EMPFED   DC    C'0'        // Carriage control character
         DC    CL26'TOTAL FEDERAL WITHHOLDING:'  // Line two total
         DC    9C' '       // 9 spaces
OTFWITH  DS    CL10        // Output field for total federal
         DC    10C' '      // 10 spaces
         DC    CL28'AVERAGE FEDERAL WITHHOLDING:' // Line two average
         DC    8C' '       // 8 spaces
OAFWITH  DS    CL10        // Output field for average federal
         DC    33C' '      // 33 spaces
*
EMPST    DC    C'0'        // Carriage control character
         DC    2C' '       // 2 spaces
         DC    CL24'TOTAL STATE WITHHOLDING:'  // Line three total
         DC    9C' '       // 9 spaces
OTSWITH  DS    CL10        // Output field for total state withholding
         DC    12C' '      // 12 spaces
         DC    CL26'AVERAGE STATE WITHHOLDING:'  // Line three average
         DC    9C' '       // 9 spaces
OASWITH  DS    CL10        // Output field for average state
         DC    30C' '      // 30 spaces
*
EMPNET   DC    C'0'        // Carriage control character
         DC    12C' '      // 12 spaces
         DC    CL14'TOTAL NET PAY:'    // Line four total net pay
         DC    9C' '       // 9 spaces
OTNETPAY DS    CL10        // Output field for total net pay
         DC    22C' '      // 22 spaces
         DC    CL16'AVERAGE NET PAY:'  // Line four average net pay
         DC    6C' '       // 6 spaces
OANETPAY DS    CL10        // Output field for average net pay
         DC    34C' '      // 34 spaces
*
****************************************************************
*                                                              *
*  SUBPROGRAM NAME: CALCNPAY                                   *
*                                                              *
*         FUNCTION: Calculate employees' federal and state     *
*                  withholding amounts and net pay.            *
*                                                              *
*       PARAMETERS: PEMPGPAY -> Employee Gross Pay             *
*                   PEMPNPAY -> Employee Net Pay               *
*                   PFWHPCT  -> Federal Withholding Percentage *
*                   PFEDWITH -> Federal Withholding Amount     *
*                   PSWHPCT  -> State Withholding Percentage   *
*                   PSTWITH  -> State Withholding Amount       *
*                                                              *
****************************************************************
*
CALCNPAY  CSECT
*
*  STANDARD ENTRY LINKAGE WITH R12 AS BASE REGISTER
*
         STM   14,12,12(13)   // Save registers in caller's save area
         LR    12,15          // Copy CSECT address into R12
         USING CALCNPAY,12    // Establish R12 as the base register
         LA    14,NTSAVE      // R14 points to this CSECT's save area
         ST    14,8(,13)      // Store address of this CSECT's save
         ST    13,4(,14)      // Store address of caller's save area
         LR    13,14          // Point R13 at this CSECT's save area
*
         LM    2,7,0(1)       // Load multiple parameters: PEMPGPAY,
*                             // PEMPNPAY, PFWHPCT, PFEDWITH,
*                             // PSWHPCT, PSTWITH
*
         ZAP   PCALC(10),0(6,2)        // Clear and set up calculation
         MP    PCALC(10),0(4,4)        // Multiply gross pay by federal
         SRP   PCALC(10),64-3,5        // Shift result right by three
         ZAP   0(6,5),PCALC(10)        // Move calculated federal
*
         ZAP   PCALC(10),0(6,2)        // Reinitialize calculation area
         MP    PCALC(10),0(4,6)        // Multiply gross pay by state
         SRP   PCALC(10),64-3,5        // Shift result right by three
         ZAP   0(6,7),PCALC(10)        // Move calculated state
*
         ZAP   PTEMP1(6),0(6,2)        // Copy gross pay to temporary
         ZAP   PTEMP2(6),0(6,5)        // Copy federal withholding
         SRP   PTEMP2(6),64-2,5        // Shift right by two places
         SP    PTEMP1(6),PTEMP2(6)     // Subtract federal withholding
         ZAP   PTEMP2(6),0(6,7)        // Copy state withholding
         SRP   PTEMP2(6),64-2,5        // Shift right by two places
         SP    PTEMP1(6),PTEMP2(6)     // Subtract state withholding
         ZAP   0(6,3),PTEMP1(6)        // Move the final net pay amount
*
*  STANDARD EXIT LINKAGE WITH RC OF 0
*
         SR    15,15        // Set R15 to 0, indicating successful
         L     13,4(,13)    // Restore pointer to caller's save area
         L     14,12(,13)   // Restore R14
         LM    0,12,20(13)  // Restore registers R0 through R12
*
         BR    14           // Return to caller
*
         LTORG              // Literal pool
*
NTSAVE   DS    18F          // Define a new save area
*
PCALC    DC    PL10'0'      // Define packed decimal for calculations
PTEMP1   DC    PL6'0'       // Temporary packed decimal
PTEMP2   DC    PL4'0'       // Another temporary packed decimal
*
*
***************************************************************
*                                                             *
*  SUBPROGRAM NAME: CALCAVG                                   *
*                                                             *
*         FUNCTION: Calculate a single average                *
*                                                             *
*       PARAMETERS: PTOTAL   -> Total used for average        *
*                   PEMPCTR  -> Employee count                *
*                   PAVG     -> Calculated average            *
*                                                             *
***************************************************************
*
CALCAVG   CSECT
*
*  STANDARD ENTRY LINKAGE WITH R12 AS BASE REGISTER
*
         STM   14,12,12(13)   // Save registers in caller's save area
         LR    12,15          // Copy CSECT address into R12
         USING CALCAVG,12     // Establish R12 as the base register
         LA    14,ATSAVE      // R14 points to this CSECT's save area
         ST    14,8(,13)      // Store address of this CSECT's save
         ST    13,4(,14)      // Store address of caller's save
         LR    13,14          // Point R13 at this CSECT's save
*
*
         LM    2,4,0(1)       // Load multiple parameters: PTOTAL,
*                             // PEMPCTR, PAVG
*
        SRP   0(3,3),2,0      // Shift left by two to adjust
        ZAP   PCALC2(10),0(7,2)    // Clear and set up calculation
        SRP   PCALC2(10),3,0       // Shift left by three
        DP    PCALC2(10),0(3,3)    // Divide total by employee count
        SRP   PCALC2(7),64-3,5     // Shift right by three to adjust
        ZAP   0(6,4),PCALC2(7)     // Copy the calculated average
*
*  STANDARD EXIT LINKAGE WITH RC OF 0
*
         SR    15,15        // Set R15 to 0, indicating successful
         L     13,4(,13)    // Restore pointer to caller's save area
         L     14,12(,13)   // Restore R14
         LM    0,12,20(13)  // Restore registers R0 through R12
*
         BR    14           // Return to caller
*
         LTORG              // Literal pool
*
ATSAVE   DS    18F          // Define a new save area
*
PCALC2   DC    PL10'0'      // Define packed decimal for calculations
*
*
         END   PAYROLL2     // End of program label
*
/*
//*
//FT06F001 DD SYSOUT=*
//*
//SYSPRINT DD SYSOUT=*
//*
/
