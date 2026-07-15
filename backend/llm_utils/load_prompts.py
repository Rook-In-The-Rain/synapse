import pathlib

def load_character_prompt(model: str) -> str:
    model_name = model.split("_")[1].lower()
    raw_prompt = open(pathlib.Path(__file__).parent.parent / "prompts" / f"misc_{model_name}.txt").read()
    return raw_prompt

def load_teacher_prompt(model: str) -> str:
    subject = model.split("_")[1].lower()
    match subject:
        case "biology":
            cachename = "BIOLOGY_TEXTBOOKS"
        case "chemistry":
            cachename = "CHEMISTRY_TEXTBOOKS"
        case "physics":
            cachename = "PHYSICS_TEXTBOOKS"
        case _:
            raise FileNotFoundError("Subject prompt doesn't exist")
    
    return cachename