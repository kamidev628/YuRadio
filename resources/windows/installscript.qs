function Component() {
    // default constructor
}

Component.prototype.createOperations = function() {
    component.createOperations();

    if (systemInfo.productType === "windows") {
      component.addOperation("CreateShortcut", "@TargetDir@/bin/YuRadio.exe", "@StartMenuDir@/YuRadio.lnk",
              "workingDirectory=@TargetDir@/bin", "description=Start YuRadio");
    }
}
