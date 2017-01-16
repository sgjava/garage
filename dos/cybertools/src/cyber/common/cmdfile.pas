{ FILE:  cmdfile.pas}



unit CmdFile;




{ ----------------------------------------------------------- }
{                                                             }
{ This unit contains all the command options for the program  }
{ and all the status line hints for the program menu options. }
{                                                             }
{ For the help commands, always ensure last item in a series  }
{ of numbers is labeled "hc????_Items" and it equals last     }
{ item in number series.                                      }
{                                                             }
{ Don't put anything else in here except key command codes!   }
{                                                             }
{ Note that in order for a command to be disabled, it MUST be }
{ in the range 100..255!                                      }
{                                                             }
{         Allowable Ranges   Reserved   Can Be Disabled       }
{                                                             }
{              0..99           Yes           Yes              }
{            100..255          No            Yes              }
{            256..999          Yes           No               }
{           1000..65535        No            No               }
{                                                             }
{ Al Andersen - 02/29/92.                                     }
{                                                             }
{ ----------------------------------------------------------- }


{$D-}



interface
uses app;


CONST



  {------------------------------------- }
  {                                      }
  { Menu commands.  Space is provided    }
  { if you want to add an "Extras" menu. }
  { If you use the extra's menu option,  }
  { put your commands here.              }
  {                                      }
  { cm??? range = 100 through 109        }
  { hc??? range = 2000 through 2099      }
  {                                      }
  { ------------------------------------ }


  cmAbout                =  100;

  hcMenus                = 2000;

  hcExtra_Menu           = 2001;
  hcAbout                = 2002;
  hcExtra_Menu_Items     = hcExtra_Menu;



  { ------------------------------- }
  {                                 }
  { FILE Menu options.              }
  {                                 }
  { The following commands may be   }
  { found in the NEWEDIT unit:      }
  {                                 }
  { cmSave                          }
  { cmSaveDone                      }
  { cmSaveAs                        }
  {                                 }
  { The following commands may be   }
  { found in the VIEWS unit:        }
  {                                 }
  { cmQuit                          }
  {                                 }
  { cm??? range =  110 through  119 }
  { hc??? range = 2100 through 2199 }
  {                                 }
  { ------------------------------- }


{ cmOpen                 =  110; }
{ cmNew                  =  111; }
{ cmChangeDir            =  112; }
{ cmShellToDos           =  113; }

  hcFile_Menu            = 2100;
{ hcOpen                 = 2101; }
{ hcNew                  = 2102; }
{ hcSave                 = 2103; }
  hcSaveDone             = 2104;
{ hcSaveAs               = 2105; }
{ hcChangeDir            = 2106; }
{ hcShellToDos           = 2107; }
{ hcExit                 = 2108; }
  hcFile_Menu_Items      = app.hcExit;



  { ------------------------------- }
  {                                 }
  { EDIT Menu options.              }
  {                                 }
  { The following commands may be   }
  { found in the VIEWS unit:        }
  {                                 }
  { cmUndo                          }
  { cmCopy                          }
  { cmCut                           }
  { cmPaste                         }
  { cmClear                         }
  {                                 }
  { cm??? range =  120 through  129 }
  { hc??? range = 2200 through 2299 }
  {                                 }
  { ------------------------------- }


  cmClipboard            =  120;
  cmSpellCheck           =  121;

  hcEdit_Menu            = 2200;
{ hcUndo                 = 2201; }
{ hcCopy                 = 2202; }
{ hcCut                  = 2203; }
{ hcPaste                = 2204; }
  hcClipboard            = 2205;
{ hcClear                = 2206; }
  hcSpellCheck           = 2207;
  hcEdit_Menu_Items      = hcSpellCheck;



  { ------------------------------- }
  {                                 }
  { SEARCH Menu options.            }
  {                                 }
  { The following commands may be   }
  { found in the NEWEDIT unit:      }
  {                                 }
  { cmFind                          }
  { cmReplace                       }
  { cmSearchAgain                   }
  {                                 }
  { cm??? range =  130 through  139 }
  { hc??? range = 2300 through 2399 }
  {                                 }
  { ------------------------------- }


  hcSearch_Menu          = 2300;
  hcFind                 = 2301;
  hcReplace              = 2302;
  hcAgain                = 2303;
  hcSearch_Menu_Items    = hcAgain;



  { ------------------------------- }
  {                                 }
  { WINDOWS Menu options.           }
  {                                 }
  { The following commands may be   }
  { found in the VIEWS unit:        }
  {                                 }
  { cmResize                        }
  { cmZoom                          }
  { cmNext                          }
  { cmPrev                          }
  { cmClose                         }
  { cmTile                          }
  { cmCascade                       }
  {                                 }
  { cm??? range =  140 through  149 }
  { hc??? range = 2400 through 2499 }
  {                                 }
  { ------------------------------- }


  hcWindows_Menu         = 2400;
{ Now found in app unit AB        }
{  hcResize               = 2401; }
{  hcZoom                 = 2402; }
{  hcPrev                 = 2403; }
{  hcNext                 = 2404; }
{  hcClose                = 2405; }
{  hcTile                 = 2406; }
{  hcCascade              = 2407; }
  hcWindows_Menu_Items   = app.hcCascade;



  { ------------------------------- }
  {                                 }
  { DESKTOP Menu options.           }
  {                                 }
  { cm??? range =  150 through  159 }
  { hc??? range = 2500 through 2599 }
  {                                 }
  { ------------------------------- }


  cmLoadDesktop          =  150;
  cmSaveDesktop          =  151;
  cmToggleVideo          =  152;

  hcDesktop_Menu         = 2500;
  hcLoadDesktop          = 2501;
  hcSaveDesktop          = 2502;
  hcToggleVideo          = 2503;
  hcDesktop_Menu_Items   = hcToggleVideo;



  { -------------------------------------------------------------------- }
  {                                                                      }
  { Miscellaneous commands not directly related to menu options go here. }
  {                                                                      }
  { -------------------------------------------------------------------- }


  hcMisc_Commands        = 2600;
  hckbShift              = 2601;
  hckbCtrl               = 2602;
  hckbAlt                = 2603;
  hcMisc_Items           = hckbAlt;



  { ------------------------------- }
  {                                 }
  { Editor help commands.           }
  {                                 }
  { Editor commands that are not    }
  { available in a menu go here.    }
  {                                 }
  { hc??? range = 2700 through 2799 }
  {                                 }
  { ------------------------------- }


  { Editor Sub Menu Commands }

  hcEditor_Commands      = 2700;
  hcCursor               = 2701;
  hcDeleting             = 2702;
  hcFormatting           = 2703;
  hcMarking              = 2704;
  hcMoving               = 2705;
  hcSaving               = 2706;
  hcSelecting            = 2707;
  hcTabbing              = 2708;

  { Editor help commands }

  hcBackSpace            = 2709;
  hcCenterText           = 2710;
  hcCharLeft             = 2711;
  hcCharRight            = 2712;
  hcDelChar              = 2713;
  hcDelEnd               = 2714;
  hcDelLine              = 2715;
  hcDelStart             = 2716;
  hcDelWord              = 2717;
  hcEndPage              = 2718;
  hcHideSelect           = 2719;
  hcHomePage             = 2720;
  hcIndentMode           = 2721;

  hcInsertLine           = 2722;
  hcInsMode              = 2723;
  hcJumpLine             = 2724;
  hcLineDown             = 2725;
  hcLineEnd              = 2726;
  hcLineStart            = 2727;
  hcLineUp               = 2728;
  hcNewLine              = 2729;
  hcPageDown             = 2730;
  hcPageUp               = 2731;
  hcReformDoc            = 2732;
  hcReformPara           = 2733;
  hcRightMargin          = 2734;
  hcScrollDown           = 2735;
  hcScrollUp             = 2736;
  hcSearchAgain          = 2737;
  hcSelectWord           = 2738;
  hcSetTabs              = 2739;
  hcStartSelect          = 2740;
  hcTabKey               = 2741;
  hcTextEnd              = 2742;
  hcTextStart            = 2743;
  hcWordLeft             = 2744;
  hcWordRight            = 2745;
  hcWordWrap             = 2746;

  hcJMarker_Menu         = 2750;
  hcJumpMark1            = 2751;
  hcJumpMark2            = 2752;
  hcJumpMark3            = 2753;
  hcJumpMark4            = 2754;
  hcJumpMark5            = 2755;
  hcJumpMark6            = 2756;
  hcJumpMark7            = 2757;
  hcJumpMark8            = 2758;
  hcJumpMark9            = 2759;
  hcJumpMark0            = 2760;
  hcJMarker_Menu_Items   = 2761;

  hcSMarker_Menu         = 2770;
  hcSetMark1             = 2771;
  hcSetMark2             = 2772;
  hcSetMark3             = 2773;
  hcSetMark4             = 2774;
  hcSetMark5             = 2775;
  hcSetMark6             = 2776;
  hcSetMark7             = 2777;
  hcSetMark8             = 2778;
  hcSetMark9             = 2779;
  hcSetMark0             = 2780;
  hcSMarker_Menu_Items   = 2781;

  hcEditor_Items         = hcSMarker_Menu_Items;



  { ----------------------------- }
  {                               }
  { Dialog box commands go here.  }
  {                               }
  { hc??? range 2800 through 2899 }
  {                               }
  { ----------------------------- }


  hcDialogs              = 2800;

  { Generic buttons }

  hcDCancel              = 2801;
  hcDNo                  = 2802;
  hcDOk                  = 2803;
  hcDYes                 = 2804;

  { About dialog }

  hcDAbout               = 2805;

  { Directory Dialog}

  hcDDirName             = 2806;
  hcDDirTree             = 2807;
  hcDChDir               = 2808;
  hcDRevert              = 2809;

  { File Dialog }

  hcDName                = 2810;
  hcDFiles               = 2811;

  { Find Dialog }

  hcDFindText            = 2812;

  { Jump Line Dialog }

  hcDLineNumber          = 2813;

  { Reformat Dialog }

  hcDReformDoc           = 2814;

  { Replace Dialog }

  hcDReplaceTExt         = 2815;

  { Right Margin Dialog }

  hcDRightMargin         = 2816;

  { Tab Stop Dialog }

  hcDTabStops            = 2817;



  { ----------------------------- }
  {                               }
  { Checkbox help for various     }
  { dialogs goes here.            }
  {                               }
  { hc??? range 2900 through 2999 }
  { ----------------------------- }


  hcCCaseSensitive       = 2900;
  hcCWholeWords          = 2901;
  hcCPromptReplace       = 2902;
  hcCReplaceAll          = 2903;
  hcCReformCurrent       = 2904;
  hcCReformEntire        = 2905;



  { ----------------------------- }
  {                               }
  { Glossary commands go here.    }
  {                               }
  { hc??? range 2900 through 2999 }
  {                               }
  {                               }
  { ----------------------------- }


  Glossary               = 3000;
  GCloseIcon             = 3001;
  GDesktop               = 3002;
  GDialogBox             = 3003;
  GHistoryIcon           = 3004;
  GInputLine             = 3005;
  GMemIndicator          = 3006;
  GMenuBar               = 3007;
  GPulldownMenu          = 3008;
  GResizeCorner          = 3009;
  GSelectedText          = 3010;
  GStatusBar             = 3011;
  GTitleBar              = 3012;
  GWindowBorder          = 3013;
  GZoomIcon              = 3014;
  hcGlossary_Items       = GZoomIcon;



implementation



end. { CmdFile }
