# -*- coding: utf-8 -*-
require "em-websocket"
logfile = File.open("vorlesung.log", 'w')


@clients = {}
@student = Hash.new
dozentReady = false

EventMachine::WebSocket.start(:host => "localhost", :port => 10081, :debug => false) do |ws|

  ws.onopen    do
    currentClientId = ws.object_id
    if !@clients.include? currentClientId
        @clients[currentClientId] = ws
    end
  end
  
  ws.onmessage do |msg| 
    currentClientId = ws.object_id
    logfile.puts 'From Client ' + currentClientId.to_s + ' received message: ' + msg

    if msg.include? 'student'
        logfile.puts "client " + currentClientId.to_s + " is a student"
        if @student.has_key?(currentClientId) && dozentReady == true
            @student[currentClientId]["wSocket"].send "id: " + currentClientId.to_s + " Rolle: Student"
            @dozent.send "Student:" + currentClientId.to_s            
        else
            @student[currentClientId] = Hash.new
            @student[currentClientId]["wSocket"] = ws
            if dozentReady == true 
                @student[currentClientId]["wSocket"].send "id: " + currentClientId.to_s + " Rolle: Student"
                @dozent.send "Student:" + currentClientId.to_s
            else 
                @student[currentClientId]["wSocket"].send "false"
            end
        end 

    elsif msg.include? 'dozent'
        dozentReady = true
        @dozent = ws
        @dozent.send "id: " + currentClientId.to_s + " Rolle: Dozent"
        @student.each {|key, value| value["wSocket"].send "ready" }
    elsif ws != @dozent
        if @dozent != nil
        logfile.puts "ws " + currentClientId.to_s + " schickt an Dozent"
        @dozent.send "#{msg}"
        else
        logfile.puts "Dozent is not ready."
        
        end      
    else
        currentStudentId = msg.slice!(0..7)      
        @clients.each do |clientId, clientWs|
            if clientId != currentClientId
                if clientId == currentStudentId.to_f
                    logfile.puts 'Dozent sendet an Student' + clientId.to_s + 'the follow message: ' + msg
                    clientWs.send "#{msg}"
                end
            end
         end
    end

  end
  
  ws.onclose {    puts "WebSocket closed"}  
  ws.onerror   { |e| puts "Error: #{e.message}" }

end
  logfile.close
