void bcmdec_workaround () {
    var bcmdec_factory = Gst.ElementFactory.find ("bcmdec");
    if (bcmdec_factory == null)
        return;

    Gst.ElementFactory factory = null_cast (bcmdec_factory);

    CrystalHD.Handle device;
    if (CrystalHD.device_open (out device) == CrystalHD.Status.SUCCESS)
        return;

    message ("CrystalHD driver installed but no device detected. %s",
        "Demoting rank");
    factory.set_rank (0);
}
