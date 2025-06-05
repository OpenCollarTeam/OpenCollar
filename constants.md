# Link Message Constants

This document lists integer constants used as the `num` parameter of `llMessageLinked` throughout the OpenCollar project. Each table row shows:
* Constant name and value
* Short description
* Parameters that accompany the call
* Scripts that send or receive the message or *common* if more than three scripts are included

Please maintain numerical sort order.

| Constant | Value | Description | Typical Parameters | Sent From | Received By |
|----------|-------|-------------|--------------------|-----------|-------------|
| CLEAR_POSE_RESTRICTION | -58937 | Clear pose based restrictions | none | cuff | cuff |
| DESUMMON_PARTICLES | -58936 | Remove cuff particle effect | from point name in `sStr` | cuff, cuff_pose | cuff |
| STOP_CUFF_POSE | -58935 | Stop all cuff animations | none | cuff | cuff |
| CLEAR_ALL_CHAINS | -58934 | Remove all active chains | none | cuff | cuff |
| REPLY_POINT_KEY | -58933 | Reply with leash point key | key in `sStr` | cuff | cuff |
| QUERY_POINT_KEY | -58932 | Query leash point key | point name in `sStr` | cuff | cuff |
| SUMMON_PARTICLES | -58931 | Cuff particle leash from one point to another | "from \| to \| age \| gravity" | cuff, cuff_pose | cuff |
| DIALOG_RENDER | -9013 | Render dialog HTML for HUDs | HTML string in `sStr` | dialog | - |
| SENSORDIALOG | -9003 | Sensor based dialog prompt | "avatarKey \| prompt \| page \| buttons \| range \| pattern \| utility \| auth" | couples, leash | dialog |
| DIALOG_TIMEOUT | -9002 | Menu timed out | "avatarKey \| page \| auth" | dialog | *common* |
| DIALOG_RESPONSE | -9001 | Response from a menu dialog | "avatarKey \| button \| page \| auth" | dialog | *common* |
| DIALOG | -9000 | Open a menu dialog | "avatarKey \| prompt \| page \| buttons \| utility \| auth" | *common* | *common* |
| LINK_CMD_RESTDATA | -2577 | Query or provide RLVa data |  | rlvextension | rlvsuite |
| LINK_CMD_RESTRICTIONS | -2576 | Request active RLV restrictions |  | rlvsuite | rlvextension, rlvsuite |
| REBOOT | -1000 | Signal scripts to reboot | "reboot" in `sStr` | core, settings, update_shim | *common* |
| STARTUP | -57 | Request startup/setting data from scripts | script name in `sStr`, `kID` empty | states | *common* |
| READY | -56 | Script initialization finished | script name in `sStr`, `kID` empty | states | *common* |
| ALIVE | -55 | Script announces it is running | script name in `sStr`, `kID` empty | *common* | states |
| CMD_ADDSRC | 11 | Add RLV source identifier | source key in `sStr` | rlvsys | - |
| CMD_REMSRC | 12 | Remove RLV source identifier | source key in `sStr` | rlvsys | - |
| CMD_OWNER | 500 | Command from an owner | chat command in `sStr`, avatar key in `kID` | *common* | *common* |
| CMD_TRUSTED | 501 | Command from trusted user | chat command in `sStr`, avatar key in `kID` | - | folders, outfits, rlvsuite |
| CMD_GROUP | 502 | Command from active group member | chat command in `sStr`, avatar key in `kID` | - | bookmarks, folders, outfits |
| CMD_WEARER | 503 | Command from wearer | chat command in `sStr`, avatar key in `kID` | rlvsys | *common* |
| CMD_EVERYONE | 504 | Command from public user | chat command in `sStr`, avatar key in `kID` | bookmarks, relay | *common* |
| CMD_RLV_RELAY | 507 | Command received via RLV relay | RLV command string in `sStr` | - | rlvsys |
| CMD_SAFEWORD | 510 | Safeword activated | optional reason in `sStr` | api, garble | *common* |
| CMD_NOACCESS | 599 | Notification of denied access |  | - | capture |
| NOTIFY | 1002 | Display a message to the wearer | level prefix + text in `sStr`, target avatar in `kID` | *common* | dialog |
| NOTIFY_OWNERS | 1003 | Notify all owners | text in `sStr`, avatar key in `kID` | *common* | dialog |
| SAY | 1004 | Cause collar to speak | text in `sStr` | *common* | dialog |
| LINK_CMD_DEBUG | 1999 | Debug or logging message | implementation specific | - | *common* |
| LM_SETTING_SAVE | 2000 | Save a setting | "token=value" in `sStr` | *common* | addons, safezone, settings |
| LM_SETTING_REQUEST | 2001 | Request a setting value | token name in `sStr` | *common* | rlvsys, settings |
| LM_SETTING_RESPONSE | 2002 | Response to setting request | "token=value" in `sStr` | *common* | *common* |
| LM_SETTING_DELETE | 2003 | Delete a stored setting | token name in `sStr` | *common* | *common* |
| LM_SETTING_EMPTY | 2004 | Setting token has no value | token name in `sStr` | settings | *common* |
| MENUNAME_REQUEST | 3000 | Query for menu registration | menu label in `sStr` | *common* | *common* |
| MENUNAME_RESPONSE | 3001 | Response with menu registration | menu label in `sStr` | *common* | *common* |
| MENUNAME_REMOVE | 3003 | Remove menu registration | menu label in `sStr` | *common* | *common* |
| RLV_CMD | 6000 | Send an RLV command | command in `sStr` | *common* | rlvsys |
| RLV_REFRESH | 6001 | Reinstate previously set restrictions | none | rlvsuite, rlvsys, states | *common* |
| RLV_CLEAR | 6002 | Clear all active restrictions | none | rlvsys | *common* |
| RLV_VERSION | 6003 | Report viewer RLV version | version string in `sStr` | rlvsys | cagehome |
| RLVA_VERSION | 6004 | Report viewer RLVa version | version string in `sStr` | rlvsys | outfits |
| RLV_CMD_OVERRIDE | 6010 | Force RLV command overriding restrictions | "command~exceptions" in `sStr` | rlvextension | rlvsys |
| RLV_OFF | 6100 | Notify plugins that RLV is disabled | none | rlvsys | *common* |
| RLV_ON | 6101 | Notify plugins that RLV is enabled | none | rlvsys | *common* |
| RLV_QUERY | 6102 | Request list of active RLV restrictions | none | - | rlvsys |
| RLV_RESPONSE | 6103 | Response to RLV_QUERY | restrictions in `sStr` | rlvsys | - |
| SIT_LINK | 6300 | Communication about avatar sitting status | "sit\|auth" or "unsit\|auth" in `sStr` | anim, rlvextension | anim, rlvextension |
| ANIM_START | 7000 | Start an animation | animation name in `sStr` | badwords, couples, shocker | anim |
| ANIM_STOP | 7001 | Stop an animation | animation name in `sStr` | badwords, couples, shocker | anim |
| ANIM_LIST_REQUEST | 7002 | Request animation list | none | badwords, shocker | - |
| ANIM_LIST_RESPONSE | 7003 | Response to animation request | list data in `sStr` | - | badwords, shocker |
| CMD_PARTICLE | 20000 | Particle effect control | implementation specific | leash | particle |
| TIMEOUT_READY | 30497 | Signals a delayed command ready |  | states | - |
| CMD_RELAY_SAFEWORD | 51200 | Relay safeword command | optional reason in `sStr` | relay | relay, rlvsys |

## Maintenance

This document can be automatically maintained by AI tools such as GitHub Copilot Agent or ChatGPT Codex. These tools can analyze the codebase to identify link message constants, determine their purpose, usage patterns, and update the documentation accordingly. When new constants are added to the codebase, simply ask an AI agent to update this document with the new entries while maintaining numerical sort order.
