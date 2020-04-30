# NBS Presentation to SPM multiple conditions converter

This simple MATLAB script reads the whole NBS Presentation log file and provides simple functions to parse it into a multiple conditions .mat file compatible with SPM. Main functionality is based on event2block function, which converts RAW event codes into blocks with some user-deifned flexibility.

## Getting Started

Look into the code and read comments. You will have to define Your conditions starting from ~120 line. The You can switch between two versions by selecting a branch name above. The defualt one (codes_by_names) enables event selection by the first letter(s) of their respective log names. The second (codes_by_ids) takes the ids from the all_codes event list.

Basic functionality of event2block function is to convert neighbouring events into blocks. However, the third argument (filter=0,1,2) enables switching between filter modes:
* no filter,
* congruent; get rid of blocks consisting of more than 2 types of events,
* mix; get rid of blocks consisting of less than 2 types of events.
What is the most important - user CAN EASILY DEFINE MORE FILTERS somewhere between lines 160 to 170.

B.

