using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class ScreenEffBase : MonoBehaviour {

    protected void CheckResources()
    {
        bool isSupport = CheckSupport();
        if (isSupport == false)
            enabled = false;
    }

    /// <summary>
    /// 检查当前平台是否支持渲染纹理和屏幕特效
    /// </summary>
    /// <returns></returns>
    protected bool CheckSupport()
    {
        if(SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            Debug.LogError("This platform does not support image effects or render textures");
            return false;
        }
        return true;
    }

    protected Material CheckShaderAndCreateMaterial(Shader shader,Material material)
    {
        if (shader == null) return null;
        if (shader.isSupported && material && material.shader == shader)
            return material;
        if(!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
                return material;
            else
                return null;
        }
    }
	// Use this for initialization
	protected void Start () {
        CheckResources();
	}
	
	// Update is called once per frame

}
