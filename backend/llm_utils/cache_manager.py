from google import genai
from google.genai import types
import pathlib

class CacheManager:
    def __init__(self, client: genai.Client, model: str):
        self.client = client
        self.model = model

    def list_all_caches(self):
        for cache in self.client.caches.list():
            print(cache.display_name, cache.usage_metadata)
    
    def clear_all_caches(self):
        for cache in self.client.caches.list():
            self.delete_cache_by_display_name(cache.display_name)

    def get_cache_name(self, display_name: str) -> str:
        for cache in self.client.caches.list():
            if cache.display_name == display_name:
                return cache.name
        print("CREATE CACHE!")
        match display_name:
            case "BIOLOGY_TEXTBOOKS":
                self.setup_biology_cache()
                return self.get_cache_name(display_name)
            case "CHEMISTRY_TEXTBOOKS":
                self.setup_chemistry_cache()
                return self.get_cache_name(display_name)
            case "PHYSICS_TEXTBOOKS":
                self.setup_physics_cache()
                return self.get_cache_name(display_name)
            case _:
                return None

    def create_textbook_cache(self, display_name: str, system_instruction: str, file_uris: list):
        content_parts = [
            types.Part.from_uri(file_uri=uri, mime_type="application/pdf") 
            for uri in file_uris
        ]

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

        print(f"Creating new cache: {display_name}...")
        cache = self.client.caches.create(
            model=self.model,
            config=types.CreateCachedContentConfig(
                display_name=display_name,
                tools=[types.Tool(google_search=types.GoogleSearch()), types.Tool(function_declarations=[update_chat_summary_declaration])],
                tool_config=types.ToolConfig(include_server_side_tool_invocations = True), 
                system_instruction=system_instruction,
                contents=content_parts,
                ttl="1800s"
            )
        )
        return cache.name

    
    def setup_biology_cache(self):
        bio_dir = pathlib.Path(__file__).parent.parent / "books" / "biology"
        book_paths = [f for f in bio_dir.iterdir() if f.is_file()]
        book_names = [self.client.files.upload(file=str(i)).uri for i in book_paths]
        sys_instruction = open(pathlib.Path(__file__).parent.parent / "prompts" / "teacherB_Aurelia.txt").read()

        self.create_textbook_cache(system_instruction=sys_instruction, display_name="BIOLOGY_TEXTBOOKS", file_uris=book_names)
    

    def setup_chemistry_cache(self):
        chem_dir = pathlib.Path(__file__).parent.parent / "books" / "chemistry"
        book_paths = [f for f in chem_dir.iterdir() if f.is_file()]
        book_names = [self.client.files.upload(file=str(i)).uri for i in book_paths]
        sys_instruction = open(pathlib.Path(__file__).parent.parent / "prompts" / "teacherC_Sizzi.txt").read()

        self.create_textbook_cache(system_instruction=sys_instruction, display_name="CHEMISTRY_TEXTBOOKS", file_uris=book_names)
    
    def setup_physics_cache(self):
        physics_dir = pathlib.Path(__file__).parent.parent / "books" / "physics"
        book_paths = [f for f in physics_dir.iterdir() if f.is_file()]
        book_names = [self.client.files.upload(file=str(i)).uri for i in book_paths]
        sys_instruction = open(pathlib.Path(__file__).parent.parent / "prompts" / "teacherP_Tensor.txt").read()

        self.create_textbook_cache(system_instruction=sys_instruction, display_name="PHYSICS_TEXTBOOKS", file_uris=book_names)


    def delete_cache_by_display_name(self, display_name: str):
        for cache in self.client.caches.list():
            if cache.display_name == display_name:
                self.client.caches.delete(name=cache.name)
                print(f"Deleted cache: {display_name}")