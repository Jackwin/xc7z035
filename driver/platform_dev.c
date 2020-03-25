#include "fpga.h"

// 完成platform_device的注册和注销
// 定义platform device，platform device的注册，定义platform driver（fpga_drv）,注册platform driver

static struct platform_device *fpga_pdev;

static int __init fpga_dev_init(void)
{
    int ret;
    // 注意此名字和platform_driver中的名字一致
    fpga_pdev = platform_device_alloc(DEVICE_NAME, -1);
    if (!fpga_pdev)
        return -ENOMEM;
    // 注册platform_device到系统
    ret = platform_device_add(fpga_pdev);
    if (ret) {
        platform_device_put(fpga_pdev);
        return ret;
    }

    return 0;
}
module_init(fpga_dev_init);

static void __exit fpga_dev_exit(void)
{
    // 从系统中注销platform_device
    platform_device_unregister(fpga_pdev);
}
module_exit(fpga_dev_exit);
