module.exports = (robot) ->
        robot.respond /accept/i, (msg) ->
                msg.reply "Thanks, you got it!"

        robot.respond /decline/i, (msg) ->
                msg.reply "OK, I'll find someone else"
                console.log "Declined!"

        robot.router.post '/pr', (req, res) ->
                data   = JSON.parse req.body.payload
                # secret = data.secret
                console.log "Got soemthing"
                room = "general"
        
                robot.messageRoom room, "Willy nilly on the googly" # "I have a secret: #{secret}"
                res.send 'OK'
