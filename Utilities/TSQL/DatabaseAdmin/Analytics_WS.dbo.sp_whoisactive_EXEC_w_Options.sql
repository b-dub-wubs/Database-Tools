/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Run Analytics_WS version of sp_whoisactive with some custom options                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
    This is an example of how to run sp_whoisactive with some options turned on to view
    inner and outer sql text as well as well as locks, block leaders, etc
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.11.06 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

EXEC Analytics_WS.dbo.sp_whoisactive 
    @output_column_list = '[session_id][dd hh:mm:ss.mss][percent_complete][sql_text][sql_command][login_name][wait_info][used_memory][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks]'
  , @get_full_inner_text  = 1
  , @get_outer_command    = 1
  , @get_locks            = 1
  , @find_block_leaders   = 1
  , @format_output        = 2
  , @get_additional_info  = 1
  , @get_transaction_info = 1
  , @get_plans            = 2



