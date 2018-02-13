using UnityEngine;
using System.Collections;

public class ReplaceShader : MonoBehaviour
{
    bool is_use = false;
    public Camera camera;
    Shader shader;
    void Start()
    {
        shader = Shader.Find("Mobile/Bumped Specular");
    }
    void OnGUI()
    {
        if (camera == null|| shader==null) return;
        if (is_use)
        {
            //var shader = Shader.Find("MyShader/Chapter10/Mirror");
            //使用高光shader：Specular来渲染Camera
            camera.RenderWithShader(shader, "RenderType");
        }
        if (GUI.Button(new Rect(10.0f, 10.0f, 300.0f, 45.0f), "使用RenderWithShader切换shader"))
        {
            //RenderWithShader每调用一次只渲染一帧，所以不可将其直接放到这儿
            //camera.RenderWithShader(Shader.Find("Specular"), "RenderType")
            is_use = true;
        }
        if (GUI.Button(new Rect(10.0f, 60.0f, 300.0f, 45.0f), "使用SetReplacementShaderi切换shader"))
        {
            //SetReplacementShader方法用来替换已有shader，调用一次即可
            //var shader = Shader.Find("MyShader/Chapter10/Mirror");
            camera.SetReplacementShader(shader, "RenderType");
            is_use = false;
        }
        if (GUI.Button(new Rect(10.0f, 110.0f, 300.0f, 45.0f), "切换回原本的shader"))
        {
            //重置摄像机的shader渲染模式
            camera.ResetReplacementShader();
            is_use = false;
        }
    }
}
