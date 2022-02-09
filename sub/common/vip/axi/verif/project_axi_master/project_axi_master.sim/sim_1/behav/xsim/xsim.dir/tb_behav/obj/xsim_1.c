/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
typedef void (*funcp)(char *, char *);
extern int main(int, char**);
IKI_DLLESPEC extern void execute_110(char*, char *);
IKI_DLLESPEC extern void execute_112(char*, char *);
IKI_DLLESPEC extern void execute_115(char*, char *);
IKI_DLLESPEC extern void execute_117(char*, char *);
IKI_DLLESPEC extern void execute_119(char*, char *);
IKI_DLLESPEC extern void execute_493(char*, char *);
IKI_DLLESPEC extern void execute_75(char*, char *);
IKI_DLLESPEC extern void execute_76(char*, char *);
IKI_DLLESPEC extern void execute_77(char*, char *);
IKI_DLLESPEC extern void execute_78(char*, char *);
IKI_DLLESPEC extern void execute_79(char*, char *);
IKI_DLLESPEC extern void execute_80(char*, char *);
IKI_DLLESPEC extern void execute_81(char*, char *);
IKI_DLLESPEC extern void execute_82(char*, char *);
IKI_DLLESPEC extern void execute_83(char*, char *);
IKI_DLLESPEC extern void execute_84(char*, char *);
IKI_DLLESPEC extern void execute_85(char*, char *);
IKI_DLLESPEC extern void execute_86(char*, char *);
IKI_DLLESPEC extern void execute_87(char*, char *);
IKI_DLLESPEC extern void execute_88(char*, char *);
IKI_DLLESPEC extern void execute_89(char*, char *);
IKI_DLLESPEC extern void execute_90(char*, char *);
IKI_DLLESPEC extern void execute_91(char*, char *);
IKI_DLLESPEC extern void execute_92(char*, char *);
IKI_DLLESPEC extern void execute_93(char*, char *);
IKI_DLLESPEC extern void execute_94(char*, char *);
IKI_DLLESPEC extern void execute_95(char*, char *);
IKI_DLLESPEC extern void execute_96(char*, char *);
IKI_DLLESPEC extern void execute_97(char*, char *);
IKI_DLLESPEC extern void execute_98(char*, char *);
IKI_DLLESPEC extern void execute_99(char*, char *);
IKI_DLLESPEC extern void execute_100(char*, char *);
IKI_DLLESPEC extern void execute_101(char*, char *);
IKI_DLLESPEC extern void execute_102(char*, char *);
IKI_DLLESPEC extern void execute_103(char*, char *);
IKI_DLLESPEC extern void execute_104(char*, char *);
IKI_DLLESPEC extern void execute_105(char*, char *);
IKI_DLLESPEC extern void execute_106(char*, char *);
IKI_DLLESPEC extern void execute_107(char*, char *);
IKI_DLLESPEC extern void execute_108(char*, char *);
IKI_DLLESPEC extern void execute_109(char*, char *);
IKI_DLLESPEC extern void svlog_sampling_process_execute(char*, char*, char*);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_1(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_2(char*, char *);
IKI_DLLESPEC extern void vlog_sv_sequence_execute_0 (char*, char*, char*);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_3(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_4(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_5(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_6(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_7(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_8(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_9(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_10(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_11(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_12(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_13(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_14(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_15(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_16(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_17(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_18(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_19(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_20(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_21(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_22(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_23(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_24(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_25(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_26(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_27(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_28(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_29(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_30(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_31(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_32(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_33(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_34(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_35(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_36(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_37(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_38(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_39(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_40(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_41(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_42(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_43(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_44(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_45(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_46(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_47(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_48(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_49(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_50(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_51(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_52(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_53(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_54(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_55(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_56(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_57(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_58(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_59(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_60(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_61(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_62(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_63(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_64(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_65(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_66(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_67(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_68(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_69(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_70(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_71(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_72(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_73(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_74(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_75(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_76(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_77(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_78(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_79(char*, char *);
IKI_DLLESPEC extern void sequence_expr_m_eccd63b3b0c57879_1caa2aac_80(char*, char *);
IKI_DLLESPEC extern void execute_124(char*, char *);
IKI_DLLESPEC extern void execute_125(char*, char *);
IKI_DLLESPEC extern void execute_126(char*, char *);
IKI_DLLESPEC extern void execute_127(char*, char *);
IKI_DLLESPEC extern void execute_494(char*, char *);
IKI_DLLESPEC extern void execute_495(char*, char *);
IKI_DLLESPEC extern void execute_496(char*, char *);
IKI_DLLESPEC extern void execute_497(char*, char *);
IKI_DLLESPEC extern void execute_498(char*, char *);
IKI_DLLESPEC extern void execute_499(char*, char *);
IKI_DLLESPEC extern void transaction_161(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void vlog_transfunc_eventcallback(char*, char*, unsigned, unsigned, unsigned, char *);
IKI_DLLESPEC extern void vlog_transfunc_eventcallback_2state(char*, char*, unsigned, unsigned, unsigned, char *);
funcp funcTab[136] = {(funcp)execute_110, (funcp)execute_112, (funcp)execute_115, (funcp)execute_117, (funcp)execute_119, (funcp)execute_493, (funcp)execute_75, (funcp)execute_76, (funcp)execute_77, (funcp)execute_78, (funcp)execute_79, (funcp)execute_80, (funcp)execute_81, (funcp)execute_82, (funcp)execute_83, (funcp)execute_84, (funcp)execute_85, (funcp)execute_86, (funcp)execute_87, (funcp)execute_88, (funcp)execute_89, (funcp)execute_90, (funcp)execute_91, (funcp)execute_92, (funcp)execute_93, (funcp)execute_94, (funcp)execute_95, (funcp)execute_96, (funcp)execute_97, (funcp)execute_98, (funcp)execute_99, (funcp)execute_100, (funcp)execute_101, (funcp)execute_102, (funcp)execute_103, (funcp)execute_104, (funcp)execute_105, (funcp)execute_106, (funcp)execute_107, (funcp)execute_108, (funcp)execute_109, (funcp)svlog_sampling_process_execute, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_1, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_2, (funcp)vlog_sv_sequence_execute_0 , (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_3, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_4, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_5, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_6, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_7, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_8, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_9, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_10, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_11, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_12, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_13, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_14, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_15, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_16, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_17, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_18, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_19, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_20, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_21, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_22, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_23, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_24, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_25, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_26, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_27, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_28, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_29, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_30, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_31, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_32, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_33, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_34, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_35, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_36, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_37, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_38, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_39, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_40, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_41, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_42, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_43, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_44, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_45, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_46, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_47, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_48, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_49, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_50, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_51, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_52, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_53, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_54, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_55, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_56, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_57, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_58, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_59, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_60, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_61, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_62, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_63, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_64, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_65, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_66, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_67, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_68, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_69, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_70, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_71, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_72, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_73, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_74, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_75, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_76, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_77, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_78, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_79, (funcp)sequence_expr_m_eccd63b3b0c57879_1caa2aac_80, (funcp)execute_124, (funcp)execute_125, (funcp)execute_126, (funcp)execute_127, (funcp)execute_494, (funcp)execute_495, (funcp)execute_496, (funcp)execute_497, (funcp)execute_498, (funcp)execute_499, (funcp)transaction_161, (funcp)vlog_transfunc_eventcallback, (funcp)vlog_transfunc_eventcallback_2state};
const int NumRelocateId= 136;

void relocate(char *dp)
{
	iki_relocate(dp, "xsim.dir/tb_behav/xsim.reloc",  (void **)funcTab, 136);

	/*Populate the transaction function pointer field in the whole net structure */
}

void sensitize(char *dp)
{
	iki_sensitize(dp, "xsim.dir/tb_behav/xsim.reloc");
}

void simulate(char *dp)
{
iki_register_root_pointers(2, 11032, 11,0,0,11216, 11,0,0) ; 
		iki_schedule_processes_at_time_zero(dp, "xsim.dir/tb_behav/xsim.reloc");
	// Initialize Verilog nets in mixed simulation, for the cases when the value at time 0 should be propagated from the mixed language Vhdl net
	iki_execute_processes();

	// Schedule resolution functions for the multiply driven Verilog nets that have strength
	// Schedule transaction functions for the singly driven Verilog nets that have strength

}
#include "iki_bridge.h"
void subprog_m_4765bd3279ad2a11_6b2de6e0_1() ;
void subprog_m_4765bd3279ad2a11_6b2de6e0_2() ;
void subprog_m_4765bd3279ad2a11_6b2de6e0_3() ;
void subprog_m_4765bd3279ad2a11_6b2de6e0_4() ;
static char* ng70[] = {(void *)subprog_m_4765bd3279ad2a11_6b2de6e0_1};
static char* ng80[] = {(void *)subprog_m_4765bd3279ad2a11_6b2de6e0_2};
static char* ng90[] = {(void *)subprog_m_4765bd3279ad2a11_6b2de6e0_3};
static char* ng100[] = {(void *)subprog_m_4765bd3279ad2a11_6b2de6e0_4};
void relocate(char *);

void sensitize(char *);

void simulate(char *);

extern SYSTEMCLIB_IMP_DLLSPEC void local_register_implicit_channel(int, char*);
extern SYSTEMCLIB_IMP_DLLSPEC int xsim_argc_copy ;
extern SYSTEMCLIB_IMP_DLLSPEC char** xsim_argv_copy ;

int main(int argc, char **argv)
{
    iki_heap_initialize("ms", "isimmm", 0, 2147483648) ;
    iki_set_sv_type_file_path_name("xsim.dir/tb_behav/xsim.svtype");
    iki_set_crvs_dump_file_path_name("xsim.dir/tb_behav/xsim.crvsdump");
    iki_svlog_initialize_virtual_tables(4, 7, ng70, 8, ng80, 9, ng90, 10, ng100);
    void* design_handle = iki_create_design("xsim.dir/tb_behav/xsim.mem", (void *)relocate, (void *)sensitize, (void *)simulate, (void*)0, 0, isimBridge_getWdbWriter(), 0, argc, argv);
     iki_set_rc_trial_count(100);
    (void) design_handle;
    return iki_simulate_design();
}
