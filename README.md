# tabby-mode

An Emacs minor mode for the [Tabby](https://tabby.tabbyml.com) AI coding assistant.

## Usage
- Set up TabbyML coding assistant according to the [guide from the official website](https://tabby.tabbyml.com/docs/welcome/)
- Set environment variables:
  - Retrieve the value of API url and authentication token from your Tabby instance and assign them to  `tabby-api-url` and `tabby-auth-token` variables
  - Toggle **tabby-mode** minor mode on
- Use interactive functions from the table below to access the desired functionality

| Keybinding | Command                   | Function Description                             |
|------------|---------------------------|--------------------------------------------------|
| `C-<tab>`  | `tabby-complete`          | Fetch code completions from the Tabby AI server. |
| `C-c a`    | `tabby-accept-suggestion` | Accept the currently displayed suggestion.       |
| `C-c t`    | `tabby-toggle-suggestion` | Cycle through available code suggestions.        |
| `C-c c`    | `tabby-clear-suggestion`  | Clear the current suggestion from the overlay.   |

## About

Original version implemented by [Ragnar Dahlén](https://github.com/ragnard) at[ragnard/tabby-mode](https://github.com/ragnard/tabby-mode).

Contributed enhancements, namely:
 - Addition of authentication token `tabby-auth-token` for the `tabby-api-url` endpoint.  
 - Alternative method for displaying suggestions, through the use of inline overlays.  
 - New interactive functions for improved user experience:  
   -  `tabby-tobble-suggestion`  
   -  `tabby-accept-suggestion`  
   -  `tabby-clear-suggestion`  

are a part of efforts falling into the scope of work for engineer's diploma thesis, titled "Quality evaluation of Tabby coding assistant and Tabby integration with Emacs text editor".  
The contribution to this package serves as a fullfillment of the second objective of the dissertation. 

