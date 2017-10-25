import java.io.*;
import org.apache.batik.transcoder.image.PNGTranscoder;
import org.apache.batik.transcoder.TranscoderInput;
import org.apache.batik.transcoder.TranscoderOutput;
import org.apache.batik.transcoder.image.ImageTranscoder;

public class SVGImporter {

    public static void main (String args[])
    {
	PNGTranscoder transcoder;
	TranscoderInput input;
	TranscoderOutput output;
	OutputStream ostream;
	String url_in, path_in, path_out;

	try {
	    switch (args.length) {
		case 2:
		    path_in = args[0];
		    path_out = args[1];
		    transcoder = new PNGTranscoder();
		    url_in = new File(path_in).toURL().toString();
		    input = new TranscoderInput(url_in);
		    ostream = new FileOutputStream(path_out);
		    output = new TranscoderOutput(ostream);
		    transcoder.addTranscodingHint(ImageTranscoder.KEY_PIXEL_TO_MM, new Float(0.2822222f));
		    transcoder.transcode(input, output);
		    ostream.flush();
		    ostream.close();
		break;
		case 4:
		    path_in = args[0];
		    path_out = args[1];
		    transcoder = new PNGTranscoder();
		    url_in = new File(path_in).toURL().toString();
		    input = new TranscoderInput(url_in);
		    ostream = new FileOutputStream(path_out);
		    output = new TranscoderOutput(ostream);
		    transcoder.addTranscodingHint(ImageTranscoder.KEY_PIXEL_TO_MM, new Float(0.2822222f));
		    transcoder.addTranscodingHint(ImageTranscoder.KEY_WIDTH, new Float(args[2]));
		    transcoder.addTranscodingHint(ImageTranscoder.KEY_HEIGHT, new Float(args[3]));
		    transcoder.transcode(input, output);
		    ostream.flush();
		    ostream.close();
		break;
	    }
	}
	catch (Exception e) {
	    System.out.println(e);
	}
    }

}
