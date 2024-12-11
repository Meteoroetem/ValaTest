#!/usr/bin/env -S vala --pkg gtk4 --pkg libsoup-3.0 --pkg json-glib-1.0

public class BasicAppSample : Gtk.Application {

    int pictureCount = 0;

    Soup.Session sess = new Soup.Session();

    public BasicAppSample () {
        Object (application_id: "com.example.BasicAppSample");
    }
    

    public override void activate () {
        var window = new Gtk.ApplicationWindow (this) {
            title = "Basic GTK4 App"
        };
        window.resizable = false;

        var picture = new Gtk.Picture();
        Bytes pictureBytes = new Bytes(null);
        var button = new Gtk.Button.with_label ("Click me!");
        var downloadButton = new Gtk.Button.with_label ("I love it! <3 Download please!!");
        var contentType = "";
        var url = "";
        button.clicked.connect (() => {
            try {
                var inStream = sess.send(new Soup.Message("GET","https://api.thecatapi.com/v1/images/search"));
                var parser = new Json.Parser();
                parser.load_from_stream (inStream);
                var jsonRoot = parser.get_root();
                url = jsonRoot.get_array().get_object_element (0).get_string_member ("url");
                var pictureRequest = new Soup.Message ("GET", url);
                pictureBytes = sess.send_and_read(pictureRequest);
                picture.set_paintable (Gdk.Texture.from_bytes(pictureBytes));
                pictureCount++;
                button.label = pictureCount == 1 ? @"you've seen one cat picture!" : @"you've seen $pictureCount cat pictures!";
                contentType = pictureRequest.response_headers.get_content_type (null);
            } catch (Error e) {
                stdout.printf(@"Error code: $(e.code)\n$(e.message)");
            }
        });
        downloadButton.clicked.connect (()=>{
            try {
                var urlSplit = url.split("/");
                var dotSplit = urlSplit[urlSplit.length-1].split(".");
                var pictureFile = File.new_for_path (@"catpic-$pictureCount.$(dotSplit[dotSplit.length-1])");
                var outStream = pictureFile.create (FileCreateFlags.NONE);
                outStream.write_bytes (pictureBytes);
            } catch (Error e) {
                stdout.printf(@"Error code: $(e.code)\n$(e.message)");
            }
        });
        
        var buttonBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        var mainBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        var centerBox = new Gtk.CenterBox();
        buttonBox.append(button);
        buttonBox.append(downloadButton);
        mainBox.append (buttonBox);
        mainBox.append (picture);
        centerBox.set_center_widget (mainBox);
        window.child = centerBox;
        window.present ();
    }

    public static int main (string[] args) {
        var app = new BasicAppSample ();
        return app.run (args);
    }
}