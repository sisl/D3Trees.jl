struct myTestType end;

SERVER = nothing


function Base.show(f::IO, m::MIME"text/html", v::myTestType)
    try
        port = 16370
        host = Sockets.localhost

        # Start server
        # close(ws_server)
        # ws_server = listen(host, port)

        # # Will contain a list of received messages
        # server_received_messages = []

        # # Start the server async
        # @async try
        #     HTTP.WebSockets.listen(host, port; verbose=true, server=ws_server) do ws
        #         for msg in ws
        #             push!(server_received_messages, msg)
        #             if msg == "close"
        #                 close(ws)
        #             else
        #                 response = "Hello, " * msg
        #                 send(ws, response)
        #             end
        #         end
        #     end
        # catch e
        #     @error "WebSocket server error" exception = (e, catch_backtrace())
        #     rethrow(e)
        # end


        js = read(joinpath(".", "client.js"), String)

        html_string = """
        <html>
        <head>
            <meta charset="UTF-8">
        </head>
        <body>

        <!-- <script src="client.js"> </script> -->
        <!-- <script src="../js/tree_vis.js">  -->
        <script>

        function setDisplay(message) {
            out = document.getElementById("myDisplay");
            out.innerHTML = message
        }     
        // === Websocket stuff
        var ws_url = "ws://$(host):$(port)";
        $js
            
        </script>

        <button type="button" id="myButton1" onclick="setDisplay('press')">
            Test!
        </button>
            
        <!-- <button type="button" onclick="sendStuff()">
            Send!
        </button>
        
        <button type="button" onclick="closeSocket()">
            Some stuff.
        </button> -->
        
        <p id="myDisplay">
            Initializing?
        </p>

        </body>
    </html>
        """

        println(f, html_string)
    catch e
        @error "Show error" exception = (e, catch_backtrace())
        rethrow(e)
    end
end