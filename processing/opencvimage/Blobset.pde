import hypermedia.video.Blob;
import java.util.Iterator;
import java.util.Vector;

public class PTBlob extends Blob {
  int xOffset;
  int yOffset;
  int thresh;
  
  public PTBlob(Blob b, int xOffset, int yOffset, int thresh) {
    super(b.area, b.length, b.centroid, b.rectangle, b.points, b.isHole);
    this.xOffset = xOffset;
    this.yOffset = yOffset;
    this.thresh = thresh;
  } 
}


public class PTBlobs  extends java.util.Vector {
  public PTBlobs() {
  }
  
  //TODO: not really push/pop
  public void push(PTBlob ptb) {
    this.add(ptb);
  }
  
  public PTBlob pop() {
    return (PTBlob)this.remove(0);
  }
  
}





public interface OscCommand {
  public String getPattern();
  public Object[] getParams();
}

public class MoveCommand implements OscCommand {
  private String pattern = "location";
  public float x;
  public float y;
  
  public MoveCommand(float x, float y) {
    this.x = x;
    this.y = y;
  }

  public String getPattern() { return this.pattern; }
  public Object[] getParams() { 
    Object[] params = new Object[2];
    params[0] = this.x;
    params[1] = this.y;
    return params;
  }
}

public class PenCommand implements OscCommand {
  private Object[] params;
  private String pattern = "pen";
  public static final String UP = "up";
  public static final String DOWN = "down";
  
  public PenCommand(String upDown) {
    this.params = new Object[1];
    this.params[0] = upDown;
  }
  public String getPattern() { return this.pattern; }
  public Object[] getParams() { return this.params; }
}


public class StatusCommand implements OscCommand {
  private Object[] params;
  private String pattern = "status";
  public static final String END = "end";
  
  public StatusCommand(String s) {
    this.params = new Object[1];
    this.params[0] = s;
  }
  public String getPattern() { return this.pattern; }
  public Object[] getParams() { return this.params; }
}

public class CommandList {
  private Vector commands;
  public CommandList() {
    this.commands = new Vector();
  }

  public void add(OscCommand cmd) {
    this.commands.add(cmd);
  }

  public boolean isEmpty() {
    return this.commands.size() <= 0;
  }

  public OscCommand removeNext() {
    return (OscCommand)this.commands.remove(0);
  }
  
  public int size() { return this.commands.size(); }
}

public class CommandGenerator  {
  private PTBlobs blobs;
  private PTBlob currentPTBlob;
  private int pointIndex = 0;
  private boolean movingToNextBlob = false;
  private CoordinateMapper cMapper;

  public CommandGenerator(PTBlobs b, CoordinateMapper c) {
    this.blobs = b;
    this.cMapper = c;
  }
  
  public CommandList generate() {
    CommandList commands = new CommandList();
    commands.add(new PenCommand(PenCommand.UP));
    Iterator iter = blobs.iterator();
    while (iter.hasNext()) {
      PTBlob b = (PTBlob)iter.next();
      for (int i=0; i<b.points.length; i++) {
        commands.add(new MoveCommand(this.cMapper.map(b.points[i].x + b.xOffset), this.cMapper.map(b.points[i].y + b.yOffset)));
        if (i==0) {
          commands.add(new PenCommand(PenCommand.DOWN));
        }
      }
      commands.add(new PenCommand(PenCommand.UP));
    }
    
    commands.add(new StatusCommand(StatusCommand.END));
    return commands;
  }

}

public class CoordinateMapper {
  private float maxDim;
  public CoordinateMapper(float max) {
    this.maxDim = max;
  } 
  
  public float map(int x) {
    return x/this.maxDim;
  }
  
  
}
