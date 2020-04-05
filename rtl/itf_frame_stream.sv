interface itf_frame_stream;

    // all signals are source -> sink
    // backpressure is not supported.

    // it is an error data_valid or error to be high while frame_valid is low.

    // high for the duration of a single frame.
    // must go low for at least one cycle before
    // starting a new frame.
    reg frame_valid;

    // the current data is valid.
    reg data_valid;

    // indicates an error in the current frame.
    // if error is high at any point, the entire frame from
    // when frame_valid went high to when frame_valid goes low
    // again must be discarded. frame_valid may stay high for an
    // undetermined amount of time after error goes low or may go
    // low in the same cycle error goes low.
    reg error;

    reg [7:0] data;

endinterface : itf_frame_stream

