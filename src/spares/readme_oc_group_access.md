# OC-Group-Access-plugin
OpenCollar plugin made to give owner-like access to members of a group.

## Configuration

In order to use the script, you should edit three configuration variables.

 * `g_sGroupId`: UUID of the group;
 * `g_sGroupInitials`: Group initials (ex: SR, DW, BFI etc.), will be used to name the App/Plugin;
 * `g_lGroupTags`: List of the group tags that will be allowed to access the collar. Leave empty to allow the entire group.

### Example
```lsl
// CONFIGURATION

// Group ID and initials
string g_sGroupId = "090134c4-0eb0-af70-c294-379c4350155c";
string g_sGroupInitials = "AC";

// Tags in the group allowed to use the collar, if empty all tags will be allowed.
list g_lGroupTags = ["Stable Mistress", "Groom"];

// End of configuration
```