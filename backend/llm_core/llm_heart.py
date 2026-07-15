from google import genai
from google.genai import types
import yaml

def ask_study_question(client: genai.Client, cache: str, chat_history: list[types.Content], uid: str, chatid: str, firestore):
    if not cache:
        raise ValueError("No book uploaded.")
    with open("./app_config.yaml", "r") as file:
        config = yaml.safe_load(file)
        model = config["ai_models"]["study_model"]
        temperature = config["ai_settings"]["study_model"]["temperature"]
        top_p = config["ai_settings"]["study_model"]["top_p"]
        cache_ttl = config["ai_settings"]["study_model"]["cache_ttl"]

    client.caches.update(name=cache, config={'ttl': f'{cache_ttl}s'})

    config = types.GenerateContentConfig(temperature=temperature, top_p=top_p, cached_content=cache)
    
    curr_summary = firestore.get_curr_summary(uid, chatid)

    if curr_summary and chat_history:
        summary_injection = f"<CHAT_SUMMARY>{curr_summary}</CHAT_SUMMARY>\n\n"
        chat_history[0].parts = [types.Part.from_text(text=summary_injection)] + list(chat_history[0].parts)

    def stream_and_record():
            current_history = chat_history 
            MAX_LOOPS_ALLOWED = 5
            loops = 0
            try:
                while loops < MAX_LOOPS_ALLOWED:
                    loops += 1
                    response_stream = client.models.generate_content_stream(model=model, contents=current_history, config=config)
                    function_calls_to_execute = []
                    model_parts = []

                    for chunk in response_stream:
                        if chunk.candidates and chunk.candidates[0].content and chunk.candidates[0].content.parts:
                            for part in chunk.candidates[0].content.parts:
                                model_parts.append(part)
                                
                                if part.function_call:
                                    function_calls_to_execute.append(part.function_call)
                                
                                if part.text:
                                    yield part.text

                    if model_parts:
                        current_history.append(types.Content(role="model", parts=model_parts))

                    if function_calls_to_execute:
                        tool_parts = []
                        
                        for fc in function_calls_to_execute:
                            if fc.name == "update_chat_summary":
                                summary_addon = fc.args.get("summary_addon")
                                if summary_addon:
                                    firestore.set_curr_summary(uid=uid, chatid=chatid, summary_text=summary_addon)
                                resp_string = "Text added to chat summary successfully." if summary_addon else "No text given!"
                                tool_parts.append(
                                    types.Part(
                                        function_response=types.FunctionResponse(
                                            name=fc.name,
                                            id=fc.id,
                                            response={"status": "success", "message": resp_string}
                                        )
                                    )
                                )
                                
                        current_history.append(types.Content(role="tool", parts=tool_parts))
                        continue 
                    break

            except Exception as e:
                yield f"Error: {e}"

    return stream_and_record()


def ask_relax_question(client: genai.Client, system_instruction: str, chat_history: list[types.Content], uid: str, user_service, chatid: str):
    with open("./app_config.yaml", "r") as file:
        config = yaml.safe_load(file)
        model = config["ai_models"]["relaxer_model"]
        temperature = config["ai_settings"]["relaxer_model"]["temperature"]
        top_p = config["ai_settings"]["relaxer_model"]["top_p"]
    
    update_user_summary_declaration = types.FunctionDeclaration(
        name="update_user_summary",
        description="Saves a new key insight, habit, preference, or fact about the user to their long-term profile summary. Appends the generated text at the end of the summary, do not rewrite what is already written",
        parameters=types.Schema(
            type="OBJECT",
            properties={
                "insight": types.Schema(
                    type="STRING",
                    description="The clear, concrete fact or insight to save (e.g., 'User prefers studying late night with snacks')."
                )
            },
            required=["insight"]
        )
    )

    update_chat_summary_declaration = types.FunctionDeclaration(
        name="update_chat_summary",
        description="Update the chat summary by adding onto it, appends the generated text at the end of the summary. Do not write what is already written. The summary is specific to this chat only and not the user and whole",
        parameters=types.Schema(
            type="OBJECT",
            properties={
                "summary_addon": types.Schema(
                    type="STRING",
                    description="The precise points you wish to add to the chat summary."
                )
            },
            required=["summary_addon"]
        )
    )
    
    
    safety_settings = [
        types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="BLOCK_NONE"),
        types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="BLOCK_NONE"),
        types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="BLOCK_NONE"),
        types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="BLOCK_NONE"),
    ]

    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        tools=[types.Tool(google_search=types.GoogleSearch()), types.Tool(function_declarations=[update_user_summary_declaration, update_chat_summary_declaration])], 
        tool_config=types.ToolConfig(include_server_side_tool_invocations = True),
        safety_settings=safety_settings,
        temperature=temperature,
        top_p=top_p,
    )
    def stream_and_record():
            current_history = chat_history
            MAX_LOOPS_ALLOWED = 5
            loops = 0
            try:
                while loops < MAX_LOOPS_ALLOWED:
                    loops += 1
                    response_stream = client.models.generate_content_stream(model=model, contents=current_history, config=config)
                    function_calls_to_execute = []
                    model_parts = []

                    for chunk in response_stream:
                        if chunk.candidates and chunk.candidates[0].content and chunk.candidates[0].content.parts:
                            for part in chunk.candidates[0].content.parts:
                                model_parts.append(part)
                                
                                if part.function_call:
                                    function_calls_to_execute.append(part.function_call)
                                
                                if part.text:
                                    yield part.text

                    if model_parts:
                        current_history.append(types.Content(role="model", parts=model_parts))

                    if function_calls_to_execute:
                        tool_parts = []
                        
                        for fc in function_calls_to_execute:
                            if fc.name == "update_user_summary":
                                insight_data = fc.args.get("insight")
                                if insight_data:
                                    user_service.set_user_summary(uid=uid, new_summary=insight_data)
                                resp_string = "Insight added to user summary successfully." if insight_data else "No insight given!"
                                tool_parts.append(
                                    types.Part(
                                        function_response=types.FunctionResponse(
                                            name=fc.name,
                                            id=fc.id,
                                            response={"status": "success", "message": resp_string}
                                        )
                                    )
                                )
                            elif fc.name == "update_chat_summary":
                                summary_addon = fc.args.get("summary_addon")
                                if summary_addon:
                                    user_service.set_curr_summary(uid=uid, chatid=chatid, summary_text=summary_addon)
                                resp_string = "Text added to chat summary successfully." if summary_addon else "No text given!"
                                tool_parts.append(
                                    types.Part(
                                        function_response=types.FunctionResponse(
                                            name=fc.name,
                                            id=fc.id,
                                            response={"status": "success", "message": resp_string}
                                        )
                                    )
                                )
                                
                        current_history.append(types.Content(role="tool", parts=tool_parts))
                        continue 
                    break

            except Exception as e:
                yield f"Error: {e}"

    return stream_and_record()