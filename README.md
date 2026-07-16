# Synapse :D
## Overview
Synapse is basically a study app, utilising AI support (and context caching with gemini at heart) to provide very NCERT (or any other textbook) focused content. The purpose was to combine already powerful LLM models but reduce the scope of their sources by providing them with concrete material to go off.

![Synapse Homepage](/readme_assets/homepage.png)
<sub>*I couldn't come up with anything else to add*</sub>

The app is divided into two core sections: the study AI and the mentor (or 'relaxer' models, idk why I named them that). The study AI are divided into the three subjects I personally studied, physics, chemistry and biology. The mentor models currently only have one (I didn't feel the need to complicate things by adding more model prompts), but the goal of these is a model to share things with. It keeps track of every user's traits and notes them down in a 'user profile' (stored in firestore).

![Mira!](/readme_assets/relaxer_chat.png)
<sub>*She's kinda mean, but I don't feel like changing prompts*</sub>

The study AI have their specific textbook sources (the NCERT in this case) loaded as context caches when a message is sent to them. These caches last an hour (arbitrary number I set, can be changed) and refresh when a new message is sent. These are the core of what allows the performance to be so high, as the AI can recall small details and page numbers (something a base model would struggle with)

![Sizzi Chem](/readme_assets/chemistry_sub.png)
<sub>*The LaTex was a pain to render.*</sub>

There are also other decorations, such as a timer until the next "NEET" exam (again, the example is based on the exam I had to give) and a quotes card which utilises the Zen-Quotes API in the backend. A settings page is also provided, which has options to change username and the theme of the app.
A full account system is of course also provided, powered mostly by Firebase Auth.

![Light Mode](/readme_assets/light_mode.png)
<sub>*RIP eyes*</sub>

![Settings](/readme_assets/settings.png)
<sub>*It looks bland ik LMAO*</sub>


## How to use

You're gonna need a `firebase_options.dart`(in the frontend) and `firebase_credentials.json`(in the backend) file, along with a `.env` file in Python to run this app, as the API keys are required. Additionally, ngrok may be downloaded. If that is not possible, then change the URL in `backend_connector.dart` in the frontend to a localhost URL

### For the frontend
- run `flutter pub get` then `flutter run -d macos` (I mostly tested this on macos only).

### For the backend
- run `ngrok http 8080` followed by `python main.py` in a separate terminal window.

## Tech Stack and details
Well, the app itself of course has a frontend and backend. A simple API connects the two.

### Frontend
The frontend is written in flutter.
> **Warning:** I have some basic support for android placed but I don't recommend using it there yet as that part is mostly unfinished (mainly the chat windows are bad on mobile).

The architecture consists of `go_router`, a shell route is utilised to keep a persistent side-drawer on screen at all times. `backend_connector.dart` is used to connect to the backend and `signup_login_manager.dart` connects to firebase auth for login. Text streaming is also handled by the frontend. I believe the file names themselves are very self-explanatory (I tried my best to make them as such).

A small comment on `chat_list_provider.dart` though: I used this system where I kept a local copy of the chatroom and messages and updated both the local copy of a chat and the database copy at once. Idk how much it improves the latency of message sending, or if it's even needed, but I didn't feel like refactoring it.

### Backend

The backend is written in python (FastAPI). The backend also houses the main LLM core in `llm_heart.py`; all the prompts for the different AI are also stored under `/prompts`. The model by default is gemini-3-flash-preview (for study AI) and gemini-3.1-flash-lite (for 'relaxer' AI), but some backend settings can be altered in `app_config.yaml`

The basic fastAPI architecture is as follows:
- The study and 'relaxer' AI clients are initialised when the backend boots up. As is obvious from the url in the frontend I used `ngrok` to help setup a dummy backend server (as opposed to using `localhost`)
- When a request arrives, the HTTP Bearer verifies the auth token (via Firebase) and returns the uid associated with the user. This uid is used for all the different endpoints
- The endpoints consist of several `GET`, `POST`, `DELETE` and `PUT` functions which all serve as wrappers to eventually call the `FirestoreManager` which makes the final changes, or gets the information required.

After this we have the actual AI backbone, here I have utilised agentic AI tooling to automate two problematic portions of writing an AI chat, that being the chat summary and the user summary.

The study AI have only one tool. They can update the chat summary when they desire, if they feel they have made meaningful progress on a topic or something of value has been said. The 'relaxer' AI have an additional tool to alter the user profile, which is a summary of the user and their traits.

This solves the issue of long chats utilising too many resources as now we can include a cut-off of around 10-20 messages in a chat, without having to worry about it forgetting the chat history entirely.

## Regarding AI assistance in programming
I built the bulk of this application in January 2026, however due to lack of time and knowledge a lot of it relied on AI generated code. So in july, after my exams I decided to revamp my code. The backend was mostly rewritten a lot of the frontend was refactored to better fit architecture.

While I am glad we have AI tools to assist us in programming, as a hobbyist programmer (not even planning to work in tech) I feel it is a waste to make it write all the code. Idk why I wanted to put this in the readme, but since this is easily the biggest project I have ever built I just want to say...

When and if I make any new projects, the utilisation of AI in their making will be the lowest possible. And I hope any other aspiring (non-corporate) developer follows the same principle :D 

## Final, Personal Remarks on this app
I was thinking of writing a more formal README, but halfway through the idea I realised something. I won't ever make a resume. Nobody will probably ever see this. Is it truly in my desire to write something formal? Not really. This was a joy to work on, the prompts, the architecture, everything. I want to take this README as more of a victory-lap for me as opposed to listing only the basics of my app.

Cheers!

---
<sub>*Made with much struggle, but at last it is done. Rook was here <3*</sub>