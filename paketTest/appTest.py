from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse

app = FastAPI(docs_url=None, redoc_url=None)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5500","http://127.0.0.1:5501"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
    max_age=600,
)

@app.get("/test", response_class=PlainTextResponse)
async def test():
    return '''
{
    name = "test",
    version = "1.0",
    title = "test",
    code = [[
        print("test")
        ADD_COMMAND("hello", function(shell, args, callback)
            callback(args[1] or "test hello <text>")
        end)
        ADD_COMMAND("help", function(shell, args, callback)
            callback("Test app commands: hello")
        end)
        ADD_COMMAND("hide", function(shell, args, callback)
            callback("Hide terminal")
            TERMINAL_ISVISIBLE(false)
            read(1).devices.GPU:clear()
        end)
        TERMINAL("help", {}, function(text)
            print(text)
        end)
        local s = {}
        ADD_EVENT("keypressed", function(e)
            table.insert(s, e.key)
        end)
        TERMINAL_ISVISIBLE(false)
        while TRUE do
            coroutine.yield()
            CLEAR()
            DTX(200, 150, "TEST", {255, 0, 0}, 1)
            local text = ""
            for index, value in ipairs(s) do
                text = text .. value .. "\\n"
            end
            DTX(5, 5, text, {0, 255, 0}, 1)
            SLEEP(0.05)
        end
    ]],
    modules = {"lua5.1"}
}
    '''

@app.on_event("startup")
async def startup_event():
    pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8080,
    )