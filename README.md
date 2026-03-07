# (Alpha) SkyrimNet_DOM
Basic SkyrimNet support for Diary of Mine. 
This is in a very rough state.

# Features 
- converts most of the DOM Events into directNarration or events 
    - DOM doesn't currently translate everything it does into events 
- Captures many dom activies as Actions 
    - full list here SKSE/Plugins/SkyrimNet_DOM/actions.json
- contains item descripts for the ropes
    - if you make more diaryofmind descriptions, please give them to me
- contains Healing Hands Trigger
    - Used to clean up all the blood, when its time for comfort
    - Cast healing (she thanks me) 
    - dialogue "\*Bring in for a warm hug\* You understand, this was your fault \*She fears, but doesn't want to believe, he may be right\*"

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
- I strongly suggestion occation DirectNarration to 'frame' events to match the story you want
