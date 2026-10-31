\# HumMac



\*\*Human-to-Machine Compiler\*\*



HumMac is an experimental compiler that explores termination-verified translation of a controlled subset of natural language into executable machine instructions.



The project investigates a termination-first compilation approach:



1\. Parse restricted natural-language instructions.

2\. Translate them into a typed formal representation.

3\. Establish whether the resulting computation belongs to a provably terminating subset.

4\. Reject expressions whose termination cannot be established.

5\. Generate bytecode for a custom virtual machine.



HumMac is an experimental research prototype, not a general-purpose natural-language compiler.



\*\*Implementation language:\*\* Haskell



\*\*Current stage:\*\* Initial development.

