java_import javax.sound.midi.MidiSystem

synth = MidiSystem.synthesizer
synth.open
channel = synth.channels[0]

frame = javax.swing.JFrame.new 'Music Frame'
frame.set_size 600, 100
frame.layout = java.awt.FlowLayout.new
notes = %w[g g# a b- b c c# d e- e f]
keys = (68..77).map { |key| key }
notes_hash = keys.zip(notes).to_h
notes_hash.each do |value, char|
  button = javax.swing.JButton.new char
  button.add_action_listener { channel.note_on value, 99 }
  frame.add button
end

frame.visible = true

## For IRB demos just type:
# synth.close

## Otherwise, this code just cleans up the synth on exit/window close
frame.default_close_operation = frame.class::EXIT_ON_CLOSE
frame.add_window_listener { |m, _a| synth.close if m == :windowClosing }
