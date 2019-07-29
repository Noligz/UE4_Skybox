using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class AutoSkyColor : MonoBehaviour
{
    public AnimationCurve Cloud_Color_R, Cloud_Color_G, Cloud_Color_B;
    public AnimationCurve Horizon_Color_R, Horizon_Color_G, Horizon_Color_B;
    public AnimationCurve Zenith_Color_R, Zenith_Color_G, Zenith_Color_B;

    public Transform SunLightTrans;

    float lastAngle = -99;
    Material targetMat;
    bool isNeedDestroyMat = true;

    int nameID_CloudColor, nameID_HorizonColor, nameID_ZenithColor;
    int nameID_StarHeight;

    void Start()
    {
        if (SunLightTrans == null)
        {
            foreach (var l in FindObjectsOfType<Light>())
            {
                if (l.type == LightType.Directional)
                {
                    SunLightTrans = l.transform;
                    break;
                }
            }
        }

        var meshRenderer = GetComponent<MeshRenderer>();
        if (meshRenderer != null)
        {
            if (Application.isPlaying)
            {
                targetMat = meshRenderer.material;
                isNeedDestroyMat = true;
            }
            else
            {
                targetMat = meshRenderer.sharedMaterial;
                isNeedDestroyMat = false;
            }
        }
        else
        {
            if (Application.isPlaying)
            {
                RenderSettings.skybox = Instantiate(RenderSettings.skybox);
                isNeedDestroyMat = true;
            }
            else
            {
                isNeedDestroyMat = false;
            }
            targetMat = RenderSettings.skybox;
        }

        nameID_CloudColor = Shader.PropertyToID("_CloudColor");
        nameID_HorizonColor = Shader.PropertyToID("_HorizonColor");
        nameID_ZenithColor = Shader.PropertyToID("_ZenithColor");
        nameID_StarHeight = Shader.PropertyToID("_StarHeight");

        if (Application.isPlaying)
            lastAngle = -99;
    }

    private void OnDestroy()
    {
        if (isNeedDestroyMat)
        {
#if UNITY_EDITOR
            DestroyImmediate(targetMat);
#else
            Destroy(targetMat);
#endif
        }
    }

    void Update()
    {
        if (SunLightTrans == null)
            return;

        var curAngle = SunLightTrans.rotation.eulerAngles.x;
        if (curAngle >= 270)
            curAngle -= 360;
        else if (curAngle >= 90 && curAngle < 270)
            curAngle = 180 - curAngle;

        if (Mathf.Approximately(curAngle, lastAngle))
            return;

        var sunHeight = curAngle / 90f;
        var cloudColor = GetEvaluateColor(Cloud_Color_R, Cloud_Color_G, Cloud_Color_B, sunHeight);
        var horizonColor = GetEvaluateColor(Horizon_Color_R, Horizon_Color_G, Horizon_Color_B, sunHeight);
        var zenithColor = GetEvaluateColor(Zenith_Color_R, Zenith_Color_G, Zenith_Color_B, sunHeight);
        var starHeight = sunHeight < 0 ? (-sunHeight) : 0;

        targetMat.SetColor(nameID_CloudColor, cloudColor);
        targetMat.SetColor(nameID_HorizonColor, horizonColor);
        targetMat.SetColor(nameID_ZenithColor, zenithColor);
        targetMat.SetFloat(nameID_StarHeight, starHeight);
    }

    Color GetEvaluateColor(AnimationCurve R, AnimationCurve G, AnimationCurve B, float time)
    {
        var r = R.Evaluate(time);
        var g = G.Evaluate(time);
        var b = B.Evaluate(time);
        return new Color(r, g, b);
    }
}
