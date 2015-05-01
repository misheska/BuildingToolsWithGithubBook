_SECRET = undefined
crypto = require 'crypto'
_API_TOKEN = undefined

anyoneButProbot = (members) ->
        user = undefined
        while not user
                user = members[ parseInt( Math.random() * members.length ) ].name
                user = undefined if "probot" == user
        user

sendPrRequest = ( robot, body, room, url, number ) ->
        parsed = JSON.parse( body )
        user = anyoneButProbot( parsed.members )
        robot.messageRoom room, "#{user}: Hey, want a PR? #{url}. Enter 'accept #{number}' to accept the PR."
        pr = exports.decodePullRequest( url )
        robot.brain.set( pr.number, url )

exports.getSecureHash = ( body ) ->
        hmac = crypto.createHmac( 'sha1', _SECRET )
        hmac.setEncoding( 'hex' )
        hmac.write( body )
        hmac.end()
        hash = hmac.read()
        console.log "Hash: #{hash}"
        hash

exports.prHandler = ( robot, req, res ) ->
        
        rawBody = req.rawBody
        body = rawBody.split( '=' ) if rawBody
        payloadData = body[1] if body and body.length == 2
        if payloadData
                decodedJson = decodeURIComponent payloadData
                pr = JSON.parse decodedJson
                
                if pr and pr.pull_request
                        url = pr.pull_request.html_url
                        number = pr.pull_request.number
                        secureHash = exports.getSecureHash( rawBody )
                        signatureKey = "x-hub-signature"
                        webhookProvidedHash = req.headers[ signatureKey ] if req?.headers
                        secureCompare = require 'secure-compare'
                        if secureCompare( "sha1=#{secureHash}", webhookProvidedHash ) and url
                                room = "general"
                                robot.http( "https://slack.com/api/users.list?token=#{process.env.HUBOT_SLACK_TOKEN}" )
                                        .get() (err, response, body) ->
                                                sendPrRequest( robot, body, room, url, number ) unless err
                        else
                                console.log "Invalid secret or no URL specified"
                else
                        console.log "No pull request in here"
                        
        res.send "OK\n"

_GITHUB = undefined
_PR_URL = undefined

exports.decodePullRequest = (url) ->
        rv = {}
        console.log "Decoding url: #{url}"
        if url
                chunks = url.split "/"
                if chunks.length == 7
                        rv.user = chunks[3]
                        rv.repo = chunks[4]
                        rv.number = chunks[6]
                console.log "RV: #{require( 'util' ).inspect( rv )}"
        rv

exports.getUsernameFromResponse = ( res ) ->
        res.message.user.name

exports.usernameMatchesGitHubUsernames = ( name, collaborators ) ->
        rv = false
        if collaborators
                for collaborator in collaborators
                        if collaborator.username == name
                                rv = true
        rv

exports.accept = ( robot, res ) ->

        prNumber = res.match[1]
        console.log "Accepted request for #{prNumber}"
        url = robot.brain.get( prNumber )

        msg = exports.decodePullRequest( url )
        username = exports.getUsernameFromResponse( res )
        msg.collabuser = username

        console.log "Username: #{username}"

        _GITHUB.repos.getCollaborator msg, ( err, collaborators ) ->
        # _GITHUB.repos.getCollaborators msg, ( err, collaborators ) ->
                if true or exports.usernameMatchesGitHubUsernames( username, collaborators )
                
                        msg.body = "@#{username} will review this (via Probot)."
                
                        _GITHUB.issues.createComment msg, ( err, data ) ->
                                unless err
                                        res.reply "Thanks, I've noted that in a PR comment. Review the PR here: "
                                else
                                        res.reply "Something went wrong, I could not tag you on the PR comment: #{require('util').inspect( err )}"
                
exports.decline = ( res ) ->
        res.reply "OK, I'll find someone else."
        console.log "Declined!"

exports.setApiToken = (github, token) ->
        _API_TOKEN = token
        _GITHUB = github
        _GITHUB.authenticate type: "oauth", token: token

exports.setSecret = (secret) ->
        _SECRET = secret
