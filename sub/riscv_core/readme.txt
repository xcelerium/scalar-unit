   // Notes
   
   // mstatus.VS is set to Dirty at vu dispatch time
   //    This will not account for vu instruction w/ exception
   //       but VS=Dirty can be more concervative
   // VU barrier instruction will need to be executed before swapping VU context
   
   // Exception Handling Support
   // Processor can operate in 
   //     Normal Mode     - pipelined, high-performance, poor visibility (imprecise exc)
   //     Serialized Mode - low-perf, good visibility (precise exc)
   // Normal Mode exception handling
   //   Precise exceptions are supported for SU-only code, excluding bus-errors (imprecise only)
   //   Imprecise exceptions for SU/VU mixed code
   //       This is dictated by overall uArch choice - decoupled operation, no re-order buffer
   //   VU exceptions are imprecise wrt SU (and mixed) code stream, however,
   //   "VU-precise" - VU exceptions are precise wrt VU-only code stream
   //      VU exceptions are taken in VU code order
   //      As all imprecise exc, it is not a resumable trap - a "post-mortem", but
   //      it is very useful for debug if it has a consistent VU state
   // Serialized Mode exception handling
   //   Instruction is issued only after previous instruction completes
   //   All exceptions are precise
   //   This is a debug assist mode

   // VU Exception Handling to support "VU-precise" handling
   //  All VU instructions complete in-order
   //     issues: VALU v. VLD/VST, etc...
   //  When VU instr has an exception:
   //    - saves vstart
   //    - does not write to VRF (from vstart and beyond)
   //    - sets (extended-Arch) Exc sticky bit in VU
   //  When Exc bit is set VU 
   //    prevents any VU instruction from performing WB
   //    discards any and all VU instructions
   //    allows VLD/VST responses to complete, but discards data (does not block pipeline)
   //  sends in-order VU instr complete status to SU
   //    Indicates except, vstart
   //    Following VU instrs should not complete
   //  On SU side, this "VU-precise" exc generates an irq (imprecise wrt SU code)
   //    VU instr PC, vlen, vstart, (VLD/VST addr) are saved and available for debug
   //  Exc Handler
   //    Check that VU has no outstanding operations (examine status bit through CSR)
   //    clear Exc bit using special instr
   //    Save context/Examine VRF using vu instructions
   
   // VU maintains
   //  Exc   - extended-Arch sticky bit

   // VU handling questions
   //  SU code reading VU status requires serialization (implicit barrier) w/ VU
   //     vcsr - (contains vxsat)
   //     vxsat - Arch sticky bit
   //     vstart
   //     mstatus.VS - Vector Status {Off, Initial, Clean, Dirty}
   //        this is problematic - part of mstatus that contains other unrelated fields
   //        writing VS=Initial (C/D?) can be used to clear VU.Exc bit
   //        How is Dirty set?? 
   //           Can be set during VU disp  (it's ok to be conservative). But, this is not VU-precise
   //           Can be set at VU completion. More VU-precise, but SU-decoupled/imprecise
   //             reading mstatus (mstatus.VS) precisely requires implcit serialization w/ VU.
   //             Use explicit VU barrier before reading mstatus.VS ?
   //      
   //  VU "vill" - Vector Type illegal
   //     vill exception can be precise. Would require serializing w/ VU
   //
