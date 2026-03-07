# (Alpha) SkyrimNet_DOM
Basic SkyrimNet support for Diary of Mine. 
This is in a very rough state.

# Features 
- converts most of the DOM Events into directNarration or events 
    - DOM doesn't currently translate everything it does into events 
- Captures many dom activies as Actions 
    - full list here SKSE/Plugins/SkyrimNet_DOM/actions.json

# Required
- SkyrimNet (dependencies)
- SkyrimNet_sexlab (dependencies) 

# Notes 
- DOM has it's own arousal system
    - This means arousal changing modes are ignored 
    - This includes SLSO, it does really change DOM's arousal 
- DOM is very spamming, ie it spends out far too many events then we can send to the LLM
    - They will be in history, but it is your job to provide Direct Narration or dialgoue to give context 
- DOM has it's own internal obedience logic, this means you will with some frequency get the LLM saying yes
  and DOM saying no. You will just have to roll with it. 